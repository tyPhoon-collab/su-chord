import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import 'chroma_calculator.dart';
import 'magnitudes_calculator.dart';

///再割り当て法を元にクロマを算出する
///時間軸方向の再割り当てはリアルタイム処理の場合、先読みが必要になるので一旦しない前提
class ReassignmentChromaCalculator extends ReassignmentCalculator
    implements ChromaCalculable, HasMagnitudeScalar {
  ReassignmentChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    this.chromaContext = const ChromaContext(),
    super.scalar,
  }) : super.hanning();

  final ChromaContext chromaContext;

  late WeightedHistogram2d histogram2d;
  Bin binX = [];
  late final Bin binY = chromaContext.toEqualTemperamentBin();

  @override
  String toString() => 'sparse, ${scalar.name}, $chromaContext';

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    final (points, magnitudes) = reassign(data, flush);
    binX = List.generate(
        magnitudes.length + 1, (i) => i * deltaTime(data.sampleRate));
    histogram2d = WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: binY,
    );
    return histogram2d.values.map(_fold).toList();
  }

  Chroma _fold(List<double> value) {
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
}
