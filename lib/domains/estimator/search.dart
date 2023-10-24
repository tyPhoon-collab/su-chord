import '../chord.dart';
import '../chord_selector.dart';
import '../chroma.dart';
import '../note_extractor.dart';
import 'estimator.dart';

///此木の論文を元に実装
///探索木に関しては、「推定された音を含むコード群を返す」計算なので、
///計算量は増える<O(log(n)) -> O(n)>が同じ動作をする関数として実装している
class SearchTreeChordEstimator extends SelectableChromaChordEstimator {
  SearchTreeChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.noteExtractable = const ThresholdByMaxRatioExtractor(),
    Set<Chord>? detectableChords,
  })  : detectableChords =
            detectableChords ?? ChromaChordEstimator.defaultDetectableChords,
        assert(
          chordSelectable is! FirstChordSelector,
          'Search Tree SHOULD NOT use FirstChordSelector as chordSelectable',
        );

  final Set<Chord> detectableChords;
  final NoteExtractable noteExtractable;

  @override
  String toString() => 'search tree $noteExtractable, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    final notes = noteExtractable(chroma);
    return detectableChords
        .where((e) => notes.every((note) => e.notes.contains(note)));
  }
}

///クロマから演奏音を抽出し、その演奏音全てを含むコードのみを返す
///もし、複数ある場合は、[ChordSelectable]によって絞り込みを行う
class FromNotesChordEstimator extends SelectableChromaChordEstimator {
  FromNotesChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.noteExtractable = const ThresholdByMaxRatioExtractor(),
    Set<Chord>? detectableChords,
  }) : detectableChords =
            detectableChords ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> detectableChords;
  final NoteExtractable noteExtractable;

  @override
  String toString() => 'from notes $noteExtractable, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    final chords = Chord.fromNotes(noteExtractable(chroma)).toSet();
    return chords.intersection(detectableChords);
  }
}