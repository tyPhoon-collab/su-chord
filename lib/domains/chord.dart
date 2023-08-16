import 'package:flutter/widgets.dart';

import 'chroma.dart';
import 'equal_temperament.dart';

typedef Notes = List<Note>;
typedef Degree = int;
typedef Degrees = Iterable<Degree>;

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
  Degrees get degrees => switch (this) {
        ChordType.major => [0, 4, 7],
        ChordType.minor => [0, 3, 7],
        ChordType.diminish => [0, 3, 6],
        ChordType.augment => [0, 4, 8],
        ChordType.sus2 => [0, 2, 7],
        ChordType.sus4 => [0, 5, 7],
      };

  String get label => switch (this) {
        ChordType.major => '',
        ChordType.minor => 'm',
        ChordType.diminish => 'dim',
        ChordType.augment => 'aug',
        ChordType.sus2 => 'sus2',
        ChordType.sus4 => 'sus4',
      };
}

///コードタイプに追加で付与されうる音
enum ChordQuality {
  sixth,
  seventh,
  majorSeventh,
  flatNinth,
  ninth,
  sharpNinth,
  eleventh,
  sharpEleventh,
  flatThirteenth,
  thirteenth;

  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  Degree get degree => switch (this) {
        ChordQuality.sixth => 9,
        ChordQuality.seventh => 10,
        ChordQuality.majorSeventh => 11,
        ChordQuality.flatNinth => 13,
        ChordQuality.ninth => 14,
        ChordQuality.sharpNinth => 15,
        ChordQuality.eleventh => 17,
        ChordQuality.sharpEleventh => 18,
        ChordQuality.flatThirteenth => 20,
        ChordQuality.thirteenth => 21,
      };
}

@immutable
class Chord {
  Chord({required this.notes, this.qualities = const {}});

  Chord.fromType(
      {required this.type, required this.root, this.qualities = const {}})
      : notes = [
          ...type.degrees.map((e) => root.to(e)),
          ...qualities.map((e) => root.to(e.degree)),
        ];

  late final String label = _parse();
  late final PCP pcp = PCP.fromNotes(notes);

  //TODO impl
  late final Note root;
  late final ChordType type;

  final Notes notes;
  final Set<ChordQuality> qualities;

  //TODO impl this
  ///Notesからlabelを導く関数
  String _parse() {
    return '';
  }
}
