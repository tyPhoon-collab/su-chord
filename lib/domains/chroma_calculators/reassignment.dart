import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../cache_manager.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import '../magnitudes_calculator.dart';
import 'chroma_calculator.dart';

abstract class ReassignmentChromaCalculator
    with SampleRateCacheManager
    implements ChromaCalculable, HasMagnitudes {
  ReassignmentChromaCalculator({
    required this.reassignmentCalculator,
    this.chromaContext = ChromaContext.guitar,
  });

  final ChromaContext chromaContext;
  final ReassignmentCalculator reassignmentCalculator;

  @override
  String toString() =>
      'sparse ${!reassignmentCalculator.isReassignFrequency ? 'non reassign frequency ' : ''}${magnitudeScalar.name} scaled, $chromaContext';

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    updateCacheSampleRate(data.sampleRate);
    final (points, magnitudes) = reassignmentCalculator.reassign(data, flush);
    return calculateFromPoints(points, magnitudes);
  }

  @protected
  List<Chroma> calculateFromPoints(List<Point> points, Magnitudes magnitudes);

  @override
  double deltaTime(int sampleRate) =>
      reassignmentCalculator.deltaTime(sampleRate);

  @override
  MagnitudeScalar get magnitudeScalar => reassignmentCalculator.scalar;
}

///ET scale => weighted histogram based on frequencies from the equal-tempered scale
///再割り当て後、平均律に従って重み付きヒストグラムをかける
final class ReassignmentETScaleChromaCalculator
    extends ReassignmentChromaCalculator {
  ReassignmentETScaleChromaCalculator({
    required super.reassignmentCalculator,
    super.chromaContext,
  });

  late final _binY = chromaContext.toEqualTemperamentBin();
  late final _hzList = chromaContext.toHzList();

  @override
  List<Chroma> calculateFromPoints(List<Point> points, Magnitudes magnitudes) {
    final binX = List.generate(
      magnitudes.length + 1,
      (i) => i * deltaTime(cachedSampleRate!),
    );
    final histogram2d = WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: _binY,
    );

    final mags = histogram2d.values;

    return mags.map(_fold).toList();
  }

  Chroma _fold(Magnitude value) {
    return PCP(List.generate(12, (i) {
      double sum = 0;

      //折りたたむ
      for (var j = 0; j < chromaContext.perOctave; j++) {
        final index = i + 12 * j;
        sum += value[index];
      }
      return sum;
    })).shift(-chromaContext.lowest.note.degreeIndexTo(Note.C));
  }

  @override
  double frequency(int index, int sampleRate) => _hzList[index];

  @override
  double indexOfFrequency(double freq, int sampleRate) {
    final deltaList = _hzList.map((e) => (e - freq).abs()).toList();
    return deltaList.indexOf(deltaList.min).toDouble();
  }
}
