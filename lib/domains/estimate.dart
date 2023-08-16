import 'package:collection/collection.dart';

import '../config.dart';
import '../utils/loader.dart';
import 'chord.dart';
import 'chroma.dart';

typedef ChordProgression = List<Chord>;

abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data);
}

class PatternMatchingChordEstimator implements ChordEstimable {
  PatternMatchingChordEstimator(
      {required this.chromaCalculable, List<Chord>? templates})
      : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? Config.defaultTemplateChords;

  final ChromaCalculable chromaCalculable;
  final List<Chord> templates;

  ChromaCalculable get _c => chromaCalculable;

  @override
  List<Chord> estimate(AudioData data) {
    final chromas = _c.chroma(data);

    return chromas
        .map((e) => maxBy(templates, (t) => e.cosineSimilarity(t.pcp))!)
        .toList();
  }
}
