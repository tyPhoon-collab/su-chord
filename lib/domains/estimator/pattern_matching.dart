import 'package:collection/collection.dart';

import '../chord.dart';
import '../chroma.dart';
import 'estimator.dart';

abstract interface class TemplateChromaScalable {
  Chroma call(Chroma c);
}

class ThirdHarmonicChromaScalar implements TemplateChromaScalable {
  const ThirdHarmonicChromaScalar(this.factor);

  final double factor;

  @override
  String toString() => 'third harmonic scalar-$factor';

  @override
  Chroma call(Chroma c) {
    return (c * factor).shift(7) + c;
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
  final TemplateChromaScalable? scalar;

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
