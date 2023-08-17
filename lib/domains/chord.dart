import 'package:flutter/widgets.dart';

import 'chroma.dart';
import 'equal_temperament.dart';

typedef Notes = List<Note>;
typedef Degree = int;
typedef Degrees = Iterable<Degree>;

///基本的なコードタイプ
///テンションなどはChordクラスで管理する
enum ChordType {
  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  major(degrees: [0, 4, 7], label: ''),
  minor(degrees: [0, 3, 7], label: 'm'),
  diminish(degrees: [0, 3, 6], label: 'dim'),
  augment(degrees: [0, 4, 8], label: 'aug'),
  sus2(degrees: [0, 2, 7], label: 'sus2'),
  sus4(degrees: [0, 5, 7], label: 'sus4');

  const ChordType({required this.degrees, required this.label});

  final Degrees degrees;
  final String label;
}

///コードタイプに追加で付与されうる音
enum ChordQuality {
  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  sixth(degree: 9, label: '6', combinable: false),
  seventh(degree: 10, label: '7', combinable: false),
  majorSeventh(degree: 11, label: 'M7', combinable: false),
  flatNinth(degree: 13, label: 'b9'),
  ninth(degree: 14, label: '9'),
  sharpNinth(degree: 15, label: '#9'),
  eleventh(degree: 17, label: '11'),
  sharpEleventh(degree: 18, label: '#11'),
  flatThirteenth(degree: 20, label: 'b13'),
  thirteenth(degree: 21, label: '13');

  const ChordQuality(
      {required this.degree, required this.label, this.combinable = true});

  final Degree degree;
  final String label;
  final bool combinable;
}

@immutable
class ChordQualities extends Iterable<ChordQuality> {
  ChordQualities(this.values)
      : assert(values.where((e) => !e.combinable).length <= 1);

  final Set<ChordQuality> values;
  late final String label = _label();

  static final empty = ChordQualities(const {});

  @override
  Iterator<ChordQuality> get iterator => values.iterator;

  String _label() {
    final base = values.where((e) => !e.combinable).firstOrNull?.label ?? '';

    final tensions = values.where((e) => e.combinable);

    if (tensions.isEmpty) {
      return base;
    } else if (tensions.length == 1) {
      return '${base}add${tensions.first.label}';
    } else {
      return '$base(${tensions.map((e) => e.label).join(",")})';
    }
  }
}

@immutable
class Chord {
  Chord({
    required this.notes,
    required this.root,
    this.qualities,
  }) : assert(notes.contains(root));

  Chord.fromType({required this.type, required this.root, this.qualities})
      : notes = [
          ...type.degrees.map((e) => root.to(e)),
          ...?qualities?.map((e) => root.to(e.degree)),
        ];

  late final String label = root.label + type.label + (qualities?.label ?? '');
  late final PCP pcp = PCP.fromNotes(notes);

  //TODO impl
  final Note root;
  late final ChordType type;

  final Notes notes;
  final ChordQualities? qualities;
}
