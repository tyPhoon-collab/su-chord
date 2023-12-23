import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../chord.dart';
import '../chord_selector.dart';
import '../chroma.dart';
import '../chroma_calculators/chroma_calculator.dart';
import '../chroma_mapper.dart';
import '../equal_temperament.dart';
import '../filters/chord_change_detector.dart';
import '../filters/filter.dart';
import '../score_calculator.dart';
import 'estimator.dart';

class TemplateContext {
  TemplateContext({
    ScoreCalculator? scoreCalculator,
    this.scoreThreshold,
    this.scalar,
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? ChromaChordEstimator.defaultDetectableChords,
        scoreCalculator = scoreCalculator ?? const ScoreCalculator.cosine();

  factory TemplateContext.harmonicScaling({
    int until = 4,
    double factor = 0.6,
    Set<Chord>? templates,
    ScoreCalculator? scoreCalculator,
    double? scoreThreshold,
  }) =>
      TemplateContext(
        scalar: HarmonicsChromaScalar(until: until, factor: factor),
        scoreCalculator: scoreCalculator,
        scoreThreshold: scoreThreshold,
        templates: templates,
      );

  final Set<Chord> templates;
  final ScoreCalculator scoreCalculator;
  final double? scoreThreshold;
  final ChromaMappable? scalar;

  late final threshold = scoreThreshold ?? double.negativeInfinity;
  late final templateChromas = _toTemplate();

  Map<Chroma, List<Chord>> _toTemplate() => groupBy(
        templates,
        (p0) => scalar?.call(p0.unitPCP) ?? p0.unitPCP,
      );

  @override
  String toString() => '$scoreCalculator ${scalar ?? 'none'} template scaled';
}

class PatternMatchingChordEstimator extends SelectableChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordChangeDetectable,
    super.overridable,
    super.chordSelectable,
    super.filters,
    TemplateContext? context,
  }) : context = context ?? TemplateContext();

  final TemplateContext context;

  @override
  String toString() => 'matching $context, ${super.toString()}';

  //TODO 計算量削減
  @override
  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma) {
    List<Chord>? chords;
    double maxScore = double.negativeInfinity;

    for (final MapEntry(:key, :value) in context.templateChromas.entries) {
      final score = context.scoreCalculator(chroma, key);
      if (score >= context.threshold && score > maxScore) {
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
    ChromaChordEstimatorOverridable? overridable,
    TemplateContext? context,
    ChordSelectable? chordSelectable,
    List<ChromaListFilter>? filters,
  }) =>
      PatternMatchingChordEstimator(
        chromaCalculable: chromaCalculable ?? this.chromaCalculable,
        chordChangeDetectable:
            chordChangeDetectable ?? this.chordChangeDetectable,
        overridable: overridable ?? this.overridable,
        chordSelectable: chordSelectable ?? this.chordSelectable,
        context: context ?? this.context,
        filters: filters ?? this.filters,
      );
}

class MeanTemplateContext extends TemplateContext {
  MeanTemplateContext({
    super.scoreCalculator,
    super.scoreThreshold,
    super.templates,
    super.scalar,
    this.meanScalar,
    this.sortedScoreTakeCount = 2,
  }) : assert(sortedScoreTakeCount <= 12);

  factory MeanTemplateContext.harmonicScaling({
    int until = 4,
    double factor = 0.6,
    Set<Chord>? templates,
    ScoreCalculator? scoreCalculator,
    double? scoreThreshold,
    int sortedScoreTakeCount = 2,
    ChromaMappable? meanScalar,
  }) =>
      MeanTemplateContext(
        scalar: HarmonicsChromaScalar(until: until, factor: factor),
        scoreCalculator: scoreCalculator,
        scoreThreshold: scoreThreshold,
        templates: templates,
        sortedScoreTakeCount: sortedScoreTakeCount,
        meanScalar: meanScalar,
      );

  final int sortedScoreTakeCount;
  final ChromaMappable? meanScalar;

  late final meanTemplateChromas = _toMeanTemplate();

  ///key  : 平均化されたPCPのクロマ
  ///value: 平均化されたPCPに使用されたテンプレートPCPとコード群のMap
  Map<Chroma, Map<Chroma, List<Chord>>> _toMeanTemplate() {
    Chroma scaledPCP(Chord e) => scalar?.call(e.unitPCP) ?? e.unitPCP;

    return Map.fromEntries(Note.sharpNotes
        .map((e) => templates.where((chord) => chord.root == e))
        .where((chords) => chords.isNotEmpty)
        .map((chords) {
      final mean = chords
          .map((e) => scaledPCP(e))
          .reduce((value, element) => value + element);

      return MapEntry(
        meanScalar?.call(mean) ?? mean,
        groupBy(chords, (e) => scaledPCP(e)),
      );
    }));
  }
}

///ルート音を基準としてグループ化する
class MeanTemplatePatternMatchingChordEstimator
    extends SelectableChromaChordEstimator {
  MeanTemplatePatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordChangeDetectable,
    super.overridable,
    super.chordSelectable,
    super.filters,
    MeanTemplateContext? context,
  }) : context = context ?? MeanTemplateContext();

  final MeanTemplateContext context;

  @override
  String toString() => 'mean matching $context, ${super.toString()}';

  @override
  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma) {
    return MultiChordCell.first(
      _sortedChromaWithScore(chroma)
          .take(context.sortedScoreTakeCount)
          .map((scoreRecord) => _maxScoreChords(chroma, scoreRecord))
          .expand((e) => e)
          .toList(),
    );
  }

  List<({Chroma chroma, double score})> _sortedChromaWithScore(Chroma chroma) {
    return context.meanTemplateChromas.keys
        .map((e) => (
              chroma: e,
              score: context.scoreCalculator(chroma, e),
            ))
        .sorted((a, b) => b.score.compareTo(a.score));
  }

  List<Chord> _maxScoreChords(
    Chroma chroma,
    ({Chroma chroma, double score}) scoreRecord,
  ) {
    List<Chord> chords = const [];
    var maxScore = double.negativeInfinity;

    for (final MapEntry(:key, :value)
        in context.meanTemplateChromas[scoreRecord.chroma]!.entries) {
      final score = context.scoreCalculator(chroma, key);
      final weightedScore = score * scoreRecord.score;
      if (score >= context.threshold && weightedScore > maxScore) {
        maxScore = weightedScore;
        chords = value;
      }
    }

    return chords;
  }

  @visibleForTesting
  MeanTemplatePatternMatchingChordEstimator copyWith({
    ChromaCalculable? chromaCalculable,
    ChromaChordChangeDetectable? chordChangeDetectable,
    ChromaChordEstimatorOverridable? overridable,
    ChordSelectable? chordSelectable,
    List<ChromaListFilter>? filters,
    MeanTemplateContext? context,
  }) =>
      MeanTemplatePatternMatchingChordEstimator(
        chromaCalculable: chromaCalculable ?? this.chromaCalculable,
        chordChangeDetectable:
            chordChangeDetectable ?? this.chordChangeDetectable,
        overridable: overridable ?? this.overridable,
        chordSelectable: chordSelectable ?? this.chordSelectable,
        filters: filters ?? this.filters,
        context: context ?? this.context,
      );
}
