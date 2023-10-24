import 'dart:math';

import 'package:collection/collection.dart';

import '../chord.dart';
import '../chroma.dart';
import 'estimator.dart';

abstract interface class ChromaScalable {
  Chroma call(Chroma c);
}

///３倍音のみ考慮する
class ThirdHarmonicChromaScalar implements ChromaScalable {
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
class HarmonicsChromaScalar implements ChromaScalable {
  HarmonicsChromaScalar({
    this.baseFactor = 0.6,
    this.until = 4,
  }) : _factors = List.generate(
          until,
          (index) => (
            harmonicIndex: _harmonics[index],
            factor: pow(baseFactor, index).toDouble(),
          ),
        );

  final int until;
  final double baseFactor;
  final Iterable<({int harmonicIndex, double factor})> _factors;

  static const _harmonics = [0, 12, 19, 24];

  @override
  String toString() => 'harmonic $baseFactor-$until';

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
    this.scalar,
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> templates;
  final ChromaScalable? scalar;

  late final templateChromas = groupBy(
    templates,
    (p0) => scalar?.call(p0.pcp) ?? p0.pcp,
  );

  @override
  String toString() => 'matching $scalar template scaled, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    return maxBy(
      templateChromas.entries,
      (entry) => chroma.cosineSimilarity(entry.key),
    )!
        .value;
  }
}
