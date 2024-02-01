import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../chord_cell.dart';
import '../chord_selector.dart';
import '../chroma.dart';
import '../chroma_calculators/chroma_calculator.dart';
import '../chroma_mapper.dart';
import '../filters/chord_change_detector.dart';
import '../filters/filter.dart';
import '../score_calculator.dart';
import 'estimator.dart';

abstract class TemplateContext {
  TemplateContext(this.detectableChords)
      : assert(detectableChords.isNotEmpty, detectableChords.toString());

  final Set<Chord> detectableChords;

  late final templateChromas = buildTemplateChroma();

  Map<Chroma, List<Chord>> buildTemplateChroma() =>
      groupBy(detectableChords, buildTemplate);

  Chroma buildTemplate(Chord chord);
}

class Template extends TemplateContext {
  Template(super.detectableChords) : super();

  @override
  Chroma buildTemplate(Chord chord) => PCP.template(chord);

  @override
  String toString() => 'unit';
}

class ScaledTemplate extends TemplateContext {
  ScaledTemplate(
    super.detectableChords, {
    required this.scalar,
  }) : super();

  ScaledTemplate.overtoneBy4th(super.detectableChords, {double factor = 0.6})
      // ignore: avoid_redundant_argument_values
      : scalar = HarmonicsChromaScalar(until: 4, factor: factor),
        super();

  ScaledTemplate.overtoneBy6th(super.detectableChords, {double factor = 0.6})
      : scalar = HarmonicsChromaScalar(until: 6, factor: factor),
        super();

  final ChromaMappable scalar;

  @override
  Chroma buildTemplate(Chord chord) => scalar(PCP.template(chord));

  @override
  String toString() => 'overtone $scalar';
}

class PatternMatchingChordEstimator extends SelectableChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordChangeDetectable,
    super.overridable,
    super.chordSelectable,
    super.filters,
    this.scoreCalculator = const ScoreCalculator.cosine(),
    double? scoreThreshold,
    required this.context,
  })  : scoreThreshold = scoreThreshold ?? double.negativeInfinity,
        super();

  final TemplateContext context;
  final ScoreCalculator scoreCalculator;
  final double scoreThreshold;

  @override
  String toString() =>
      '$scoreCalculator matching $context, ${super.toString()}';

  @override
  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma) {
    List<Chord>? chords;
    double maxScore = double.negativeInfinity;

    for (final MapEntry(:key, :value) in context.templateChromas.entries) {
      final score = scoreCalculator(chroma, key);
      if (score >= scoreThreshold && score > maxScore) {
        maxScore = score;
        chords = value;
      }
    }

    return MultiChordCell.first(chords ?? const []);
  }

  @visibleForTesting
  PatternMatchingChordEstimator copyWith({
    ChromaCalculable? chromaCalculable,
    ChromaChordChangeDetectable? chordChangeDetectable,
    ScoreCalculator? scoreCalculator,
    double? scoreThreshold,
    ChromaChordEstimatorOverridable? overridable,
    TemplateContext? context,
    ChordSelectable? chordSelectable,
    List<ChromaListFilter>? filters,
  }) =>
      PatternMatchingChordEstimator(
        chromaCalculable: chromaCalculable ?? this.chromaCalculable,
        chordChangeDetectable:
            chordChangeDetectable ?? this.chordChangeDetectable,
        scoreCalculator: scoreCalculator ?? this.scoreCalculator,
        scoreThreshold: scoreThreshold ?? this.scoreThreshold,
        overridable: overridable ?? this.overridable,
        chordSelectable: chordSelectable ?? this.chordSelectable,
        context: context ?? this.context,
        filters: filters ?? this.filters,
      );
}
