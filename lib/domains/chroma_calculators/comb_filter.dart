import 'package:collection/collection.dart';

import '../../utils/formula.dart';
import '../../utils/loaders/audio.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import '../magnitudes_calculator.dart';
import 'chroma_calculator.dart';

class CombFilterContext {
  const CombFilterContext({
    this.hzStdDevCoefficient = 1 / 72,
    this.kernelRadiusStdDevMultiplier = 3,
  });

  @override
  String toString() =>
      '${hzStdDevCoefficient.toStringAsFixed(3)} $kernelRadiusStdDevMultiplier';

  ///周波数fに依存する標準偏差。f * hzStdDevCoefficient
  final double hzStdDevCoefficient;
  final double kernelRadiusStdDevMultiplier;
}

class EmbeddedMagnitudesCalculable {
  const EmbeddedMagnitudesCalculable(this.magnitudesCalculable);

  final MagnitudesCalculable magnitudesCalculable;

  MagnitudeScalar get magnitudeScalar => magnitudesCalculable.magnitudeScalar;

  double frequency(int index, int sampleRate) =>
      magnitudesCalculable.frequency(index, sampleRate);

  double indexOfFrequency(double freq, int sampleRate) =>
      magnitudesCalculable.indexOfFrequency(freq, sampleRate);

  double deltaTime(int sampleRate) =>
      magnitudesCalculable.deltaTime(sampleRate);
}

///コムフィルタを使用してクロマを求める
class CombFilterChromaCalculator extends EmbeddedMagnitudesCalculable
    implements ChromaCalculable, HasMagnitudes {
  CombFilterChromaCalculator(
    super.magnitudesCalculable, {
    this.chromaContext = ChromaContext.guitar,
    this.context = const CombFilterContext(),
  });

  final CombFilterContext context;
  final ChromaContext chromaContext;

  late final _hzList = chromaContext.toHzList();

  @override
  String toString() =>
      'normal distribution comb filter, $magnitudesCalculable, $chromaContext';

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    return magnitudesCalculable(data, flush)
        .map((e) => _fold(calculatePowers(e, data.sampleRate)))
        .toList();
  }

  Chroma _fold(Chroma value) {
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

  ///各音階ごとに正規分布によるコムフィルタを適用した結果を取得する
  ///正規分布の平均値は各音階の周波数、標準偏差は[CombFilterContext]の値を参照する
  Chroma calculatePowers(Magnitude magnitude, int sr) =>
      Chroma(_hzList.map((e) => calculatePower(magnitude, sr, e)).toList());

  double calculatePower(Magnitude magnitude, int sr, double hz) {
    final mean = hz;
    final stdDev = hz * context.hzStdDevCoefficient;
    // 正規分布の端っこの方は値がほとんど0であるため、計算量削減のため畳み込む範囲を指定する
    final kernelRadius = context.kernelRadiusStdDevMultiplier * stdDev;
    final closure = normalDistributionClosure(mean, stdDev);

    final startIndex = indexOfFrequency(mean - kernelRadius, sr).round();
    final endIndex = indexOfFrequency(mean + kernelRadius, sr).round();

    return magnitude
        .sublist(startIndex, endIndex)
        .mapIndexed((j, e) => closure(frequency(j + startIndex, sr)) * e)
        .sum;
  }
}
