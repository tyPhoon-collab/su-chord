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
  String toString() => '$hzStdDevCoefficient-$kernelRadiusStdDevMultiplier';

  ///周波数fに依存する標準偏差。f * hzStdDevCoefficient
  final double hzStdDevCoefficient;
  final double kernelRadiusStdDevMultiplier;
}

///コムフィルタを使用してクロマを求める
class CombFilterChromaCalculator implements ChromaCalculable, HasMagnitudes {
  CombFilterChromaCalculator({
    required this.magnitudesCalculable,
    this.chromaContext = ChromaContext.guitar,
    this.context = const CombFilterContext(),
  }) : super();

  final CombFilterContext context;
  final ChromaContext chromaContext;
  final MagnitudesCalculable magnitudesCalculable;

  @override
  String toString() =>
      'normal distribution comb filter, $magnitudesCalculable, $chromaContext';

  @override
  MagnitudeScalar get magnitudeScalar => magnitudesCalculable.magnitudeScalar;

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    return magnitudesCalculable(data, flush)
        .map((e) => Chroma(
              List.generate(
                12,
                (i) => _getCombFilterPower(
                  e,
                  data.sampleRate,
                  chromaContext.lowest.transpose(i),
                ),
              ),
            ).shift(-chromaContext.lowest.note.degreeIndexTo(Note.C)))
        .toList();
  }

  ///各音階ごとに正規分布によるコムフィルタを適用した結果を取得する
  ///正規分布の平均値は各音階の周波数、標準偏差は[CombFilterContext]の値を参照する
  double _getCombFilterPower(Magnitude magnitude, int sr, Pitch lowest) {
    double sum = 0;
    for (int i = 0; i < chromaContext.perOctave; ++i) {
      final mc = magnitudesCalculable; //short handle name
      final scale = lowest.transpose(i * 12);
      final hz = scale.toHz();

      final mean = hz;
      final stdDev = hz * context.hzStdDevCoefficient;
      // 正規分布の端っこの方は値がほとんど0であるため、計算量削減のため畳み込む範囲を指定する
      final kernelRadius = context.kernelRadiusStdDevMultiplier * stdDev;
      final closure = normalDistributionClosure(mean, stdDev);

      final startIndex = mc.indexOfFrequency(mean - kernelRadius, sr).round();
      final endIndex = mc.indexOfFrequency(mean + kernelRadius, sr).round();

      sum += magnitude
          .sublist(startIndex, endIndex)
          .mapIndexed((j, e) => closure(mc.frequency(j + startIndex, sr)) * e)
          .sum;
    }

    return sum;
  }

  @override
  double frequency(int index, int sampleRate) =>
      magnitudesCalculable.frequency(index, sampleRate);

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      magnitudesCalculable.indexOfFrequency(freq, sampleRate);

  @override
  double deltaTime(int sampleRate) =>
      magnitudesCalculable.deltaTime(sampleRate);
}
