import 'package:collection/collection.dart';

import '../config.dart';
import '../utils/loader.dart';
import 'chord.dart';
import 'chord_change_detector.dart';
import 'chroma.dart';
import 'equal_temperament.dart';

class ChordProgression extends Iterable<Chord> {
  ChordProgression(this.values);

  final Iterable<Chord> values;

  @override
  Iterator<Chord> get iterator => values.iterator;

  @override
  String toString() => values.map((e) => e.label).join('->');
}

abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data);
}

class PatternMatchingChordEstimator implements ChordEstimable {
  PatternMatchingChordEstimator({
    required this.chromaCalculable,
    required this.chordChangeDetectable,
    List<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? Config.defaultTemplateChords;

  final ChromaCalculable chromaCalculable;
  final ChordChangeDetectable chordChangeDetectable;
  final List<Chord> templates;

  ChromaCalculable get _cc => chromaCalculable;

  ChordChangeDetectable get _ccd => chordChangeDetectable;

  @override
  ChordProgression estimate(AudioData data) {
    final chromas = _ccd.reduce(_cc.chroma(data));

    return ChordProgression(
      chromas.map((e) => maxBy(templates, (t) => e.cosineSimilarity(t.pcp))!),
    );
  }
}

//此木の論文を元に実装
class SearchTreeChordEstimator implements ChordEstimable {
  SearchTreeChordEstimator({
    required this.chromaCalculable,
    required this.chordChangeDetectable,
    this.thresholdRatio = 0.65,
  });

  final ChromaCalculable chromaCalculable;
  final ChordChangeDetectable chordChangeDetectable;
  final double thresholdRatio;

  ChromaCalculable get _cc => chromaCalculable;

  ChordChangeDetectable get _ccd => chordChangeDetectable;

  @override
  ChordProgression estimate(AudioData data) {
    final chromas = _ccd.reduce(_cc.chroma(data));

    //TODO nullに対応させる
    return ChordProgression(
      chromas.map((e) => Chord.fromNotes(_chooseNotes(e)).first),
    );
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
    final indexes = chroma.sortedIndex;
    final max = chroma[indexes.first];
    final threshold = max * thresholdRatio;
    return indexes
        .toList()
        .sublist(0, 4)
        .where((e) => chroma[e] >= threshold)
        .map((e) => Note.fromIndex(e));
  }
}
