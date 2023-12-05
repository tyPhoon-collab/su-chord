import 'package:collection/collection.dart';

import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../cache_manager.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import '../magnitudes_calculator.dart';
import 'chroma_calculator.dart';

///再割り当て後、平均律に従って重み付きヒストグラムをかける
class ReassignmentEqualTemperamentBinCalculator extends ReassignmentCalculator
    with MagnitudesCacheManager
    implements HasMagnitudes {
  ReassignmentEqualTemperamentBinCalculator({
    super.chunkSize,
    super.chunkStride,
    super.isReassignFrequency,
    super.isReassignTime,
    this.chromaContext = ChromaContext.guitar,
    super.scalar,
  }) : super.hanning();

  final ChromaContext chromaContext;

  WeightedHistogram2d? histogram2d;
  late final _binY = chromaContext.toEqualTemperamentBin();
  late final _hzList = chromaContext.toHzList();

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  Magnitudes calculateMagnitudes(AudioData data, [bool flush = true]) {
    final (points, magnitudes) = reassign(data, flush);
    final binX = List.generate(
        magnitudes.length + 1, (i) => i * deltaTime(data.sampleRate));
    histogram2d = WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: _binY,
    );

    final mags = histogram2d!.values;

    updateCacheMagnitudes(mags, flush);

    return mags;
  }

  @override
  double frequency(int index, int sampleRate) => _hzList[index];

  @override
  double indexOfFrequency(double freq, int sampleRate) {
    final deltaList = _hzList.map((e) => (e - freq).abs()).toList();
    return deltaList.indexOf(deltaList.min).toDouble();
  }
}

class ReassignmentChromaCalculator
    extends ReassignmentEqualTemperamentBinCalculator
    with MagnitudesCacheManager
    implements ChromaCalculable, HasMagnitudes {
  ReassignmentChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    super.isReassignFrequency,
    super.isReassignTime,
    super.chromaContext,
    super.scalar,
  }) : super();

  @override
  String toString() =>
      'sparse ${!isReassignFrequency ? 'non reassign frequency ' : ''}${scalar.name} scaled, $chromaContext';

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    final mags = calculateMagnitudes(data, flush);
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
}
