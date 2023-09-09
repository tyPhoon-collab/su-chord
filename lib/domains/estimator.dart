import 'package:collection/collection.dart';

import '../config.dart';
import '../utils/loader/audio.dart';
import '../utils/measure.dart';
import 'chord.dart';
import 'chord_progression.dart';
import 'chord_selector.dart';
import 'chroma.dart';
import 'equal_temperament.dart';
import 'filter.dart';

abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data, [bool flush = true]);

  ChordProgression flush();
}

abstract interface class Debuggable {
  Iterable<String> debugText();
}

///Chromaからコードを推定する場合は、このクラスを継承すると良い
abstract class ChromaChordEstimator
    with Measure
    implements ChordEstimable, Debuggable {
  ChromaChordEstimator(
      {required this.chromaCalculable, this.filters = const []});

  final ChromaCalculable chromaCalculable;
  final Iterable<ChromaListFilter> filters;

  //Debugs
  List<Chroma> chromas = [];
  List<Chroma> reducedChromas = [];

  @override
  ChordProgression estimate(AudioData data, [bool flush = true]) {
    final chroma = measure('chroma calc', () => chromaCalculable(data, flush));
    chromas.addAll(chroma);

    reducedChromas = List.of(chromas);
    measure('filter calc', () {
      for (final e in filters) {
        reducedChromas = e(reducedChromas);
      }
    });

    final progression = estimateFromChroma(reducedChromas);

    if (flush) _flush();
    return progression;
  }

  @override
  ChordProgression flush() {
    return estimate(AudioData.empty());
  }

  void _flush() {
    chromas = [];
    // reducedChromas = [];
  }

  ChordProgression estimateFromChroma(List<Chroma> chroma);

  @override
  Iterable<String> debugText() {
    return [
      ...reducedChromas.map((e) => e.toString()),
      ...calculateTimes.entries.map((entry) => '${entry.key}: ${entry.value}')
    ];
  }
}

enum TemplatePCPScalarType {
  ///３倍音を操作する
  ///３倍音は3fの整数倍倍音で、平均律では12+4度が該当する
  thirdHarmonic,
  none;
}

class TemplatePCPScalar {
  const TemplatePCPScalar({required this.type, required this.factor});

  factory TemplatePCPScalar.thirdHarmonic(double factor) => TemplatePCPScalar(
        type: TemplatePCPScalarType.thirdHarmonic,
        factor: factor,
      );

  static const none = TemplatePCPScalar(
    type: TemplatePCPScalarType.none,
    factor: 0,
  );

  final TemplatePCPScalarType type;
  final double factor;

  PCP call(PCP pcp) {
    switch (type) {
      case TemplatePCPScalarType.thirdHarmonic:
        return ((pcp * factor).shift(16) + pcp).toPCP();
      case TemplatePCPScalarType.none:
        return pcp;
    }
  }
}

class PatternMatchingChordEstimator extends ChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    ChordSelectable? chordSelectable,
    super.filters,
    this.scalar = TemplatePCPScalar.none,
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        chordSelectable = chordSelectable ?? FirstChordSelector(),
        templates = templates ?? Config.detectableChords;

  final Set<Chord> templates;
  final TemplatePCPScalar scalar;

  final ChordSelectable chordSelectable;
  late final Map<Chroma, List<Chord>> templateChromas =
      groupBy(templates, (p0) => scalar(p0.pcp));

  @override
  ChordProgression estimateFromChroma(List<Chroma> chroma) {
    final progression = ChordProgression.empty();
    for (final c in chroma) {
      final chords = maxBy(
          templateChromas.entries, (entry) => c.cosineSimilarity(entry.key))!;
      final chord = chordSelectable.select(chords.value, progression);
      progression.add(chord);
    }
    return progression;
  }
}

///此木の論文を元に実装
///内部的には探索木を用いてはいないが、
///クロマから音高を導き、音高からコードを導くという点では全く同じ動作をする
class SearchTreeChordEstimator extends ChromaChordEstimator {
  SearchTreeChordEstimator({
    required super.chromaCalculable,
    ChordSelectable? chordSelectable,
    super.filters,
    this.thresholdRatio = 0.65,
    Set<Chord>? detectableChords,
  })  : chordSelectable = chordSelectable ?? FirstChordSelector(),
        detectableChords = detectableChords ?? Config.detectableChords;

  final double thresholdRatio;
  final ChordSelectable chordSelectable;
  final Set<Chord> detectableChords;

  @override
  ChordProgression estimateFromChroma(List<Chroma> chroma) {
    final progression = ChordProgression.empty();
    for (final c in chroma) {
      final chord = chordSelectable.select(_chooseChords(c), progression);
      progression.add(chord);
    }
    return progression;
  }

  Iterable<Chord> _chooseChords(Chroma chroma) {
    final chords = Chord.fromNotes(_chooseNotes(chroma)).toSet();
    return chords.intersection(detectableChords);
  }

  // 5.4 演奏音推定モジュール
  // PCP に対する演奏音の検出処理の過程を図 5.4 に示す.
  // 同図において，指定時間長における PCP の各クロマごとのパワーの平均が計算され (A)，
  // 降順に 4 つのクロマが選択される (B).
  // それらにおいて，最大のパワーを持つクロマが閾値を超える場合は，
  // そのクロマは第一演奏音 として決定される (C).
  // 残りの 3 つのクロマについては閾値処理により，
  // 第一演奏音に対して 65% 以上のパワーを持つ場合のみ演奏音であると見なされる (D).
  // 閾値を 65%ととした理由 は，6.3 節で述べる単音演奏の認識実験において，
  // 演奏したクロマに対して 65%以下のパワー を持つクロマはノイズ成分として見なされたためである.
  // 従って，演奏音の数は最大 4 つと なる.
  Notes _chooseNotes(Chroma chroma) {
    final indexes = chroma.maxSortedIndexes;
    final max = chroma[indexes.first];
    final threshold = max * thresholdRatio;
    final notes = indexes
        .toList()
        .sublist(0, 4)
        .where((e) => chroma[e] >= threshold)
        .map((e) => Note.fromIndex(e));

    return notes;
  }
}
