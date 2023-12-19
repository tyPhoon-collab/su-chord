import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../chord.dart';
import '../chord_selector.dart';
import '../chroma.dart';
import '../chroma_calculators/chroma_calculator.dart';
import '../equal_temperament.dart';
import '../filters/chord_change_detector.dart';
import '../filters/filter.dart';
import '../score_calculator.dart';
import 'estimator.dart';

///３倍音のみ考慮する
class OnlyThirdHarmonicChromaScalar implements ChromaMappable {
  const OnlyThirdHarmonicChromaScalar(this.factor);

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
  })  : assert(
          0 < until && until <= 6,
          'only 0-6 harmonics can incorporate for pcp this class',
        ),
        _factors = List.generate(
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
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    List<Chord>? chords;
    double maxScore = double.negativeInfinity;

    for (final MapEntry(:key, :value) in _templateChromas.entries) {
      final score = scoreCalculator(chroma, key);
      if (score >= _threshold && score > maxScore) {
        maxScore = score;
        chords = value;
      }
    }

    return chords ?? const [];
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
            .cast<Chroma>()
            .reduce((value, element) => value + element);

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
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    List<Chord> chords = const [];
    var maxScore = double.negativeInfinity;
    final sortedScoreRecords =
        _sortedChromaWithScore(chroma).take(context.sortedScoreTakeCount);

    for (final scoreRecord in sortedScoreRecords) {
      for (final MapEntry(:key, :value)
          in _meanTemplateChromas[scoreRecord.chroma]!.entries) {
        final score = scoreCalculator(chroma, key);
        //weight by mean template PCP score
        //優先度を平均化されたPCPのスコア順にするために、スコアをかける
        //こうすることで、m7と6系の異名同和音の区別が容易になる場合がある
        //ただ、そこの選択は別クラスでも行うため、いらないかも
        //TODO: 仕様の検討
        final weightedScore = score * scoreRecord.score;
        if (score >= _threshold && weightedScore > maxScore) {
          maxScore = weightedScore;
          chords = value;
        }
      }
    }

    return chords;
  }

  List<({Chroma chroma, double score})> _sortedChromaWithScore(Chroma chroma) {
    return _meanTemplateChromas.keys
        .map((e) => (
              chroma: e,
              score: scoreCalculator(chroma, e),
            ))
        .sorted((a, b) => b.score.compareTo(a.score));
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
