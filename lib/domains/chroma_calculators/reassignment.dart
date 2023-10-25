import 'package:collection/collection.dart';

import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../cache_manager.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import '../magnitudes_calculator.dart';
import 'chroma_calculator.dart';

///再割り当て法を元にクロマを算出する
///時間軸方向の再割り当てはリアルタイム処理の場合、先読みが必要になるので一旦しない前提
class ReassignmentChromaCalculator extends ReassignmentCalculator
    with MagnitudesCacheManager
    implements ChromaCalculable, HasMagnitudes {
  ReassignmentChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    super.isReassignFrequencyDimension,
    super.isReassignTimeDimension,
    this.chromaContext = ChromaContext.guitar,
    super.scalar,
  }) : super.hanning();

  final ChromaContext chromaContext;

  WeightedHistogram2d? histogram2d;
  late final _binY = chromaContext.toEqualTemperamentBin();
  late final _hzList = chromaContext.toHzList();

  @override
  String toString() => 'sparse ${scalar.name} scaled, $chromaContext';

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    final (points, magnitudes) = reassign(data, flush);
    final binX = List.generate(
        magnitudes.length + 1, (i) => i * deltaTime(data.sampleRate));
    histogram2d = WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: _binY,
    );

    updateCacheMagnitudes(histogram2d!.values, flush);

    return histogram2d!.values.map(_fold).toList();
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
    })).shift(-chromaContext.lowest.note.degreeTo(Note.C));
  }

  @override
  double time(int index, int sampleRate) => deltaTime(sampleRate) * index;

  @override
  double frequency(int index, int sampleRate) => _hzList[index];

  @override
  double indexOfFrequency(double freq, int sampleRate) {
    final deltaList = _hzList.map((e) => (e - freq).abs()).toList();
    return deltaList.indexOf(deltaList.min).toDouble();
  }
}
