import '../chord_cell.dart';
import '../chord_search_tree.dart';
import '../chroma.dart';
import '../note_extractor.dart';
import 'estimator.dart';

///此木の論文を元に実装
///探索木に関しては、「推定された音を含むコード群を返す」計算なので、
///計算量は増える<O(log(n)) -> O(n)>が同じ動作をする関数として実装している
class SearchTreeChordEstimator extends SelectableChromaChordEstimator {
  SearchTreeChordEstimator({
    required super.chromaCalculable,
    required this.context,
    super.chordChangeDetectable,
    super.chordSelectable,
    super.filters,
    this.noteExtractable = const ThresholdByMaxRatioExtractor(),
  }) : super();

  final NoteExtractable noteExtractable;
  final SearchTreeContext context;
  late final searchChords = searchChordsClosure(context);

  @override
  String toString() => 'search tree $noteExtractable, ${super.toString()}';

  @override
  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma) {
    final notes = noteExtractable(chroma);
    return MultiChordCell.first(searchChords(notes).toList());
  }
}
