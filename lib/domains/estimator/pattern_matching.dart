import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../chord.dart';
import '../chroma.dart';
import 'estimator.dart';

enum TemplateChromaScalarType {
  ///３倍音を操作する
  ///３倍音は3fの整数倍倍音で、平均律では12+4度が該当する
  thirdHarmonic,
  none;
}

@immutable
class TemplateChromaScalar {
  const TemplateChromaScalar({required this.type, required this.factor});

  factory TemplateChromaScalar.thirdHarmonic(double factor) =>
      TemplateChromaScalar(
        type: TemplateChromaScalarType.thirdHarmonic,
        factor: factor,
      );

  static const none = TemplateChromaScalar(
    type: TemplateChromaScalarType.none,
    factor: 0,
  );

  final TemplateChromaScalarType type;
  final double factor;

  @override
  String toString() => '${type.name}-$factor';

  Chroma call(Chroma c) {
    switch (type) {
      case TemplateChromaScalarType.thirdHarmonic:
        return (c * factor).shift(16) + c;
      case TemplateChromaScalarType.none:
        return c;
    }
  }
}

class PatternMatchingChordEstimator extends SelectableChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.scalar = TemplateChromaScalar.none,
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> templates;
  final TemplateChromaScalar scalar;

  late final templateChromas = groupBy(templates, (p0) => scalar(p0.pcp));

  @override
  String toString() => 'matching $scalar template scaled, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    return maxBy(templateChromas.entries,
            (entry) => chroma.cosineSimilarity(entry.key))!
        .value;
  }
}
