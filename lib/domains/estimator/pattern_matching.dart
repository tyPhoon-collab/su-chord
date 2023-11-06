import 'dart:math';

import 'package:collection/collection.dart';

import '../chord.dart';
import '../chroma.dart';
import '../score_calculator.dart';
import 'estimator.dart';

///３倍音のみ考慮する
class ThirdHarmonicChromaScalar implements ChromaMappable {
  const ThirdHarmonicChromaScalar(this.factor);

  final double factor;

  @override
  String toString() => 'third harmonic scalar-$factor';

  @override
  Chroma call(Chroma c) {
    return (c * factor).shift(7) + c;
  }
}

///Chord recognition by fitting rescaled chroma vectors to chord templates
///指数的に倍音をたたみ込む
///s^(i-1)に従う : i倍音
class HarmonicsChromaScalar implements ChromaMappable {
  HarmonicsChromaScalar({
    this.factor = 0.6,
    this.until = 4,
  }) : _factors = List.generate(
          until,
          (index) => (
            harmonicIndex: _harmonics[index],
            factor: pow(factor, index).toDouble(),
          ),
        );

  final int until;
  final double factor;
  final Iterable<({int harmonicIndex, double factor})> _factors;

  ///https://xn--i6q789c.com/gakuten/baion.html
  ///基音
  ///1オクターブ
  ///1オクターブ+完全5度
  ///2オクターブ
  ///2オクターブ+長3度
  ///2オクターブ+完全5度
  static const _harmonics = [0, 0, 7, 0, 4, 7];

  @override
  String toString() => 'harmonic $factor-$until';

  @override
  Chroma call(Chroma c) {
    Chroma chroma = Chroma.zero(c.length);
    for (final v in _factors) {
      chroma += c.shift(v.harmonicIndex) * v.factor;
    }
    return chroma;
  }
}

class PatternMatchingChordEstimator extends SelectableChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.templateScalar,
    this.scoreCalculator = const ScoreCalculator.cosine(),
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> templates;
  final ScoreCalculator scoreCalculator;
  final ChromaMappable? templateScalar;

  late final templateChromas = groupBy(
    templates,
    (p0) => templateScalar?.call(p0.unitPCP) ?? p0.unitPCP,
  );

  @override
  String toString() =>
      '$scoreCalculator matching ${templateScalar ?? 'none'} template scaled, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    return maxBy(
      templateChromas.entries,
      (entry) => scoreCalculator(chroma, entry.key),
    )!
        .value;
  }
}
