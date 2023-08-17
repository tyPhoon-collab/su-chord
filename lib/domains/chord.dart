import 'package:flutter/widgets.dart';

import 'chroma.dart';
import 'equal_temperament.dart';

typedef Notes = List<Note>;
typedef Degree = int;
typedef Degrees = Iterable<Degree>;

///基本的なコードタイプ
///テンションなどはChordクラスで管理する
///dim7, m7b5は便宜上、こちらに含める。後々別の手法で管理する可能性あり
enum ChordType {
  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  major(degrees: [0, 4, 7], label: ''),
  minor(degrees: [0, 3, 7], label: 'm'),
  diminish(degrees: [0, 3, 6], label: 'dim', availableTensions: {}),
  diminish7(degrees: [0, 3, 6, 9], label: 'dim7', availableTensions: {}),
  augment(degrees: [0, 4, 8], label: 'aug'),
  sus2(degrees: [0, 2, 7], label: 'sus2'),
  sus4(degrees: [0, 5, 7], label: 'sus4'),
  minorSeventhFlatFive(
      degrees: [0, 3, 6, 10],
      label: 'm7b5',
      availableTensions: {
        ChordQuality.ninth,
        ChordQuality.eleventh,
        ChordQuality.thirteenth
      });

  const ChordType(
      {required this.degrees,
      required this.label,
      this.availableTensions = const {...ChordQuality.values}});

  factory ChordType.fromLabel(String label) {
    for (final type in values) {
      if (type.label == label) return type;
    }
    throw ArgumentError();
  }

  bool validate(ChordQualities qualities) =>
      qualities.every((e) => availableTensions.contains(e));

  final Degrees degrees;
  final String label;
  final Set<ChordQuality> availableTensions;
}

///コードタイプに追加で付与されうる音
///combinableがfalse同士は、どんな状況であっても音楽理論的に共存し得ない
///これらの管理はChordQualitiesが行う
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

  factory ChordQuality.fromLabel(String label) {
    for (final quality in values) {
      if (quality.label == label) return quality;
    }
    throw ArgumentError();
  }

  final Degree degree;
  final String label;
  final bool combinable;
}

@immutable
class ChordQualities extends Iterable<ChordQuality> {
  ChordQualities(this.values)
      : assert(values.where((e) => !e.combinable).length <= 1);

  factory ChordQualities.fromLabel(String label) {
    //TODO 全てのQualitiesに対応させる。現在は評価実験に出てくるもののみ
    if (label.isEmpty) return empty;
    label = label.replaceAll('add', '');
    return ChordQualities({ChordQuality.fromLabel(label)});
  }

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
      : assert(qualities == null || type.validate(qualities),
            'chordType: $type, availableTensions: ${type.availableTensions}, tensions: $qualities'),
        notes = [
          ...type.degrees.map((e) => root.to(e)),
          ...?qualities?.map((e) => root.to(e.degree)),
        ];

  factory Chord.fromLabel(String chord) {
    //TODO 全てのコードタイプに対応させる。現在は評価実験に出てくるもののみ
    final exp = RegExp(
        r'([A-G][#b]?)((?:m|dim|dim7|aug|sus4|sus2|m7b5)?)((?:6|7|M7|add9)?)');
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError();

    try {
      final root = Note.fromLabel(match.group(1)!);
      final type = ChordType.fromLabel(match.group(2) ?? '');
      final qualities = ChordQualities.fromLabel(match.group(3) ?? '');

      return Chord.fromType(type: type, root: root, qualities: qualities);
    } catch (e) {
      rethrow;
    }
  }

  late final String label = root.label + type.label + (qualities?.label ?? '');
  late final PCP pcp = PCP.fromNotes(notes);

  final Note root;

  //TODO impl
  late final ChordType type;

  final Notes notes;
  final ChordQualities? qualities;
}
