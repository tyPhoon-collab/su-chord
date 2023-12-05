import 'chroma.dart';
import 'equal_temperament.dart';

abstract interface class NoteExtractable {
  Notes call(Chroma chroma);
}

class ThresholdByMaxRatioExtractor implements NoteExtractable {
  const ThresholdByMaxRatioExtractor({
    this.ratio = 0.65,
    this.maxNotesCount = 4,
  });

  final double ratio;
  final int? maxNotesCount;

  @override
  Notes call(Chroma chroma) {
    final indexes = chroma.maxSortedIndexes;
    final max = chroma[indexes.first];
    final threshold = max * ratio;
    final notes = indexes
        .toList()
        .sublist(0, maxNotesCount)
        .where((e) => chroma[e] >= threshold)
        .map((i) => Note.sharpNotes[i])
        .toList();

    return notes;
  }

  @override
  String toString() => '$ratio threshold $maxNotesCount notes';
}
