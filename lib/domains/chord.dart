import 'package:flutter/widgets.dart';

import 'chroma.dart';
import 'equal_temperament.dart';

typedef Notes = List<Note>;
typedef Degrees = Iterable<int>;

///基本的なコードタイプ
///テンションなどはChordクラスで管理する
enum ChordType {
  major,
  minor,
  diminish,
  augment,
  sus2,
  sus4;

  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  Degrees get degree => switch (this) {
        ChordType.major => [0, 4, 7],
        ChordType.minor => [0, 3, 7],
        ChordType.diminish => [0, 3, 6],
        ChordType.augment => [0, 4, 8],
        ChordType.sus2 => [0, 2, 7],
        ChordType.sus4 => [0, 5, 7],
      };
}

@immutable
class Chord {
  Chord({required this.notes});

  Chord.fromType({required ChordType type, required Note root})
      : notes = type.degree.map((e) => root.to(e)).toList();

  late final String label = _parse();
  late final PCP pcp = PCP.fromNotes(notes);
  final Notes notes;

  //TODO impl this
  ///Notesからlabelを導く関数
  String _parse() {
    return '';
  }
}
