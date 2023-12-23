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

class PatternMatchingChordEstimator extends SelectableChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordChangeDetectable,
    super.overridable,
    super.chordSelectable,
    super.filters,
    this.templateScalar,
    this.scoreCalculator = const ScoreCalculator.cosine(),
    this.scoreThreshold,
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> templates;
  final ScoreCalculator scoreCalculator;
  final double? scoreThreshold;
  final ChromaMappable? templateScalar;

  late final _templateChromas = groupBy(
    templates,
    (p0) => templateScalar?.call(p0.unitPCP) ?? p0.unitPCP,
  );
  late final _threshold = scoreThreshold ?? double.negativeInfinity;

  @override
  String toString() =>
      '$scoreCalculator matching ${templateScalar ?? 'none'} template scaled, ${super.toString()}';

  //TODO 計算量削減
  @override
  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma) {
    List<Chord>? chords;
    double maxScore = double.negativeInfinity;

    for (final MapEntry(:key, :value) in _templateChromas.entries) {
      final score = scoreCalculator(chroma, key);
      if (score >= _threshold && score > maxScore) {
        maxScore = score;
        chords = value;
      }
    }

    return MultiChordCell.first(chords ?? const []);
  }

  @visibleForTesting
  PatternMatchingChordEstimator copyWith({
    Set<Chord>? templates,
    ScoreCalculator? scoreCalculator,
    ChromaMappable? templateScalar,
    ChromaCalculable? chromaCalculable,
    ChromaChordChangeDetectable? chordChangeDetectable,
    ChromaChordEstimatorOverridable? overridable,
    ChordSelectable? chordSelectable,
    List<ChromaListFilter>? filters,
  }) =>
      PatternMatchingChordEstimator(
        templates: templates ?? this.templates,
        scoreCalculator: scoreCalculator ?? this.scoreCalculator,
        templateScalar: templateScalar ?? this.templateScalar,
        chromaCalculable: chromaCalculable ?? this.chromaCalculable,
        chordChangeDetectable:
            chordChangeDetectable ?? this.chordChangeDetectable,
        overridable: overridable ?? this.overridable,
        chordSelectable: chordSelectable ?? this.chordSelectable,
        filters: filters ?? this.filters,
      );
}

class MeanTemplateContext {
  const MeanTemplateContext({this.sortedScoreTakeCount = 2})
      : assert(sortedScoreTakeCount <= 12);

  ///key  : 平均化されたPCPのクロマ
  ///value: 平均化されたPCPに使用されたテンプレートPCPとコード群のMap
  static Map<Chroma, Map<Chroma, List<Chord>>> createMeanTemplate(
    Set<Chord> templates,
    ChromaMappable? scalar,
  ) {
    Chroma scaledPCP(Chord e) => scalar?.call(e.unitPCP) ?? e.unitPCP;

    return Map.fromEntries(Note.sharpNotes.map(
      (e) {
        final chords = templates.where((chord) => chord.root == e);
        final key = chords
            .map((e) => scaledPCP(e))
            .reduce((value, element) => value + element);
        // .toLogScale();

        return MapEntry(key, groupBy(chords, (e) => scaledPCP(e)));
      },
    ));
  }

  final int sortedScoreTakeCount;
}

///ルート音を基準としてグループ化する
class MeanTemplatePatternMatchingChordEstimator
    extends PatternMatchingChordEstimator {
  MeanTemplatePatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordChangeDetectable,
    super.overridable,
    super.chordSelectable,
    super.filters,
    super.templateScalar,
    super.scoreCalculator,
    super.scoreThreshold,
    super.templates,
    this.context = const MeanTemplateContext(),
  }) : super();

  final MeanTemplateContext context;

  late final _meanTemplateChromas = MeanTemplateContext.createMeanTemplate(
    templates,
    templateScalar,
  );

  @override
  String toString() => 'mean ${super.toString()}';

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
    return _meanTemplateChromas.keys
        .map((e) => (
              chroma: e,
              score: scoreCalculator(chroma, e),
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
        in _meanTemplateChromas[scoreRecord.chroma]!.entries) {
      final score = scoreCalculator(chroma, key);
      final weightedScore = score * scoreRecord.score;
      if (score >= _threshold && weightedScore > maxScore) {
        maxScore = weightedScore;
        chords = value;
      }
    }

    return chords;
  }

  @override
  @visibleForTesting
  MeanTemplatePatternMatchingChordEstimator copyWith({
    Set<Chord>? templates,
    ScoreCalculator? scoreCalculator,
    ChromaMappable? templateScalar,
    ChromaCalculable? chromaCalculable,
    ChromaChordChangeDetectable? chordChangeDetectable,
    ChromaChordEstimatorOverridable? overridable,
    ChordSelectable? chordSelectable,
    List<ChromaListFilter>? filters,
    MeanTemplateContext? context,
  }) =>
      MeanTemplatePatternMatchingChordEstimator(
        templates: templates ?? this.templates,
        scoreCalculator: scoreCalculator ?? this.scoreCalculator,
        templateScalar: templateScalar ?? this.templateScalar,
        chromaCalculable: chromaCalculable ?? this.chromaCalculable,
        chordChangeDetectable:
            chordChangeDetectable ?? this.chordChangeDetectable,
        overridable: overridable ?? this.overridable,
        chordSelectable: chordSelectable ?? this.chordSelectable,
        filters: filters ?? this.filters,
        context: context ?? this.context,
      );
}
