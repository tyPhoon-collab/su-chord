import 'package:flutter/widgets.dart';

import '../config.dart';
import '../utils/loader.dart';
import 'chroma.dart';
import 'equal_temperament.dart';

typedef Notes = List<Note>;
typedef TemplatePCPs = Iterable<PCP>;
typedef Degrees = Iterable<int>;

@immutable
class Chord {
  Chord({required this.notes});

  Chord.major({required Note root})
      : notes = _major.map((e) => root.to(e)).toList();

  Chord.minor({required Note root})
      : notes = _minor.map((e) => root.to(e)).toList();

  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  static const Degrees _major = [0, 4, 7];
  static const Degrees _minor = [0, 3, 7];

  late final String label = _parse();
  late final PCP pcp = PCP.fromNotes(notes);
  final Notes notes;
  
  //TODO impl this
  ///Notesからlabelを導く関数
  String _parse() {
    return '';
  }
}

abstract interface class ChordEstimable {
  List<Chord> estimate(AudioData data);
}

class PatternMatchingChordEstimator implements ChordEstimable {
  PatternMatchingChordEstimator({required this.chromaCalculable});

  final ChromaCalculable chromaCalculable;
  final TemplatePCPs templates = Config.defaultTemplates;

  ChromaCalculable get _c => chromaCalculable;

  @override
  List<Chord> estimate(AudioData data) {
    final chromas = _c.chroma(data);
    throw UnimplementedError();
  }
}
