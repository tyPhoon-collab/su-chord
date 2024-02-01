import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../chord_cell.dart';
import '../chord_selector.dart';
import '../chroma.dart';
import '../chroma_calculators/chroma_calculator.dart';
import '../chroma_mapper.dart';
import '../filters/chord_change_detector.dart';
import '../filters/filter.dart';
import '../score_calculator.dart';
import 'estimator.dart';
import 'pattern_matching.dart';

abstract class MeanTemplateContext {
  MeanTemplateContext(
    this.detectableChords, {
    required this.templateBuilder,
    this.sortedScoreTakeCount = 2,
  })  : assert(sortedScoreTakeCount <= 12),
        assert(detectableChords.isNotEmpty),
        super();

  final int sortedScoreTakeCount;
  final Set<Chord> detectableChords;
  final TemplateContext Function(Set<Chord> chords) templateBuilder;

  late final meanTemplateChromas = buildMeanTemplateChromas();

  ///key  : 平均化されたPCPのクロマ
  ///value: 平均化されたPCPに使用されたテンプレートPCPとコード群のMap
  Map<Chroma, Map<Chroma, List<Chord>>> buildMeanTemplateChromas() =>
      Map.fromIterable(
        Note.sharpNotes,
        key: (note) => buildMeanTemplate(note),
        value: (note) {
          final chords = detectableChords.where((e) => e.root == note).toSet();
          return templateBuilder(chords).buildTemplateChroma();
        },
      );

  Chroma buildMeanTemplate(Note note);
}

class MeanTemplate extends MeanTemplateContext {
  MeanTemplate(
    super.detectableChords, {
    required super.templateBuilder,
    super.sortedScoreTakeCount = 2,
  }) : super();

  factory MeanTemplate.basic(Set<Chord> detectableChords) => MeanTemplate(
        detectableChords,
        templateBuilder: Template.new,
      );

  factory MeanTemplate.overtoneBy4th(Set<Chord> detectableChords) =>
      MeanTemplate(
        detectableChords,
        templateBuilder: ScaledTemplate.overtoneBy4th,
      );

  factory MeanTemplate.overtoneBy6th(Set<Chord> detectableChords) =>
      MeanTemplate(
        detectableChords,
        templateBuilder: ScaledTemplate.overtoneBy6th,
      );

  @override
  Chroma buildMeanTemplate(Note note) {
    final templateContext = templateBuilder(detectableChords);
    return detectableChords
        .where((e) => e.root == note)
        .map(templateContext.buildTemplate)
        .fold(Chroma.zero(12), (value, element) => value + element);
  }
}

class LnMeanTemplate extends MeanTemplateContext {
  LnMeanTemplate(
    super.detectableChords, {
    required super.templateBuilder,
    super.sortedScoreTakeCount = 3,
  });

  factory LnMeanTemplate.basic(Set<Chord> detectableChords) => LnMeanTemplate(
        detectableChords,
        templateBuilder: Template.new,
      );

  factory LnMeanTemplate.overtoneBy4th(Set<Chord> detectableChords) =>
      LnMeanTemplate(
        detectableChords,
        templateBuilder: ScaledTemplate.overtoneBy4th,
      );

  factory LnMeanTemplate.overtoneBy6th(Set<Chord> detectableChords) =>
      LnMeanTemplate(
        detectableChords,
        templateBuilder: ScaledTemplate.overtoneBy6th,
      );

  @override
  Chroma buildMeanTemplate(Note note) {
    final templateContext = templateBuilder(detectableChords);

    return const LogChromaScalar().call(
      detectableChords
          .where((e) => e.root == note)
          .map(templateContext.buildTemplate)
          .fold(Chroma.zero(12), (value, element) => value + element),
    );
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
    this.scoreCalculator = const ScoreCalculator.cosine(),
    double? scoreThreshold,
    required this.context,
  })  : scoreThreshold = scoreThreshold ?? double.negativeInfinity,
        super();

  final MeanTemplateContext context;
  final ScoreCalculator scoreCalculator;
  final double scoreThreshold;

  @override
  String toString() => 'mean matching $context, ${super.toString()}';

  @override
  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma) {
    return MultiChordCell.first(
      _sortedChromaWithScore(chroma)
          .take(context.sortedScoreTakeCount)
          .map((scoreRecord) => _maxScoreChords(chroma, scoreRecord))
          .sorted((a, b) => b.score.compareTo(a.score))
          .expand((e) => e.chords)
          .toList(),
    );
  }

  List<({Chroma chroma, double score})> _sortedChromaWithScore(Chroma chroma) {
    return context.meanTemplateChromas.keys
        .map((e) => (
              chroma: e,
              score: scoreCalculator(chroma, e),
            ))
        .sorted((a, b) => b.score.compareTo(a.score));
  }

  ({List<Chord> chords, double score}) _maxScoreChords(
    Chroma chroma,
    ({Chroma chroma, double score}) scoreRecord,
  ) {
    List<Chord> chords = const [];
    var maxScore = double.negativeInfinity;

    for (final MapEntry(:key, :value)
        in context.meanTemplateChromas[scoreRecord.chroma]!.entries) {
      final score = scoreCalculator(chroma, key);
      final weightedScore = score * scoreRecord.score;
      if (score >= scoreThreshold && weightedScore > maxScore) {
        maxScore = weightedScore;
        chords = value;
      }
    }

    return (chords: chords, score: maxScore);
  }

  @visibleForTesting
  MeanTemplatePatternMatchingChordEstimator copyWith({
    ChromaCalculable? chromaCalculable,
    ChromaChordChangeDetectable? chordChangeDetectable,
    ScoreCalculator? scoreCalculator,
    double? scoreThreshold,
    ChromaChordEstimatorOverridable? overridable,
    ChordSelectable? chordSelectable,
    List<ChromaListFilter>? filters,
    MeanTemplateContext? context,
  }) =>
      MeanTemplatePatternMatchingChordEstimator(
        chromaCalculable: chromaCalculable ?? this.chromaCalculable,
        chordChangeDetectable:
            chordChangeDetectable ?? this.chordChangeDetectable,
        scoreCalculator: scoreCalculator ?? this.scoreCalculator,
        scoreThreshold: scoreThreshold ?? this.scoreThreshold,
        overridable: overridable ?? this.overridable,
        chordSelectable: chordSelectable ?? this.chordSelectable,
        filters: filters ?? this.filters,
        context: context ?? this.context,
      );
}
