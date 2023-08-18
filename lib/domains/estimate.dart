import 'package:collection/collection.dart';

import '../config.dart';
import '../utils/loader.dart';
import 'chord.dart';
import 'chord_change_detector.dart';
import 'chroma.dart';

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
