import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'chroma.dart';
import 'equal_temperament.dart';

typedef Notes = Iterable<Note>;
typedef Degree = int;
typedef Degrees = Iterable<Degree>;

///基本的なコードタイプ
///テンションなどはChordクラスで管理する
///dim7, m7b5もこちらに含める
enum ChordType {
  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  major(degrees: [0, 4, 7], label: ''),
  minor(
      degrees: [0, 3, 7],
      label: 'm',
      availableTensions: {
        ...ChordQuality.normalTensions,
        ...ChordQuality.tonicTensions
      }),
  diminish(degrees: [0, 3, 6], label: 'dim', availableTensions: {}),
  diminish7(degrees: [0, 3, 6, 9], label: 'dim7', availableTensions: {}),
  augment(degrees: [0, 4, 8], label: 'aug'),
  sus2(
      degrees: [0, 2, 7],
      label: 'sus2',
      availableTensions: {
        ...ChordQuality.normalTensions,
        ChordQuality.eleventh,
        ChordQuality.thirteenth
      }),
  sus4(
      degrees: [0, 5, 7],
      label: 'sus4',
      availableTensions: {
        ...ChordQuality.normalTensions,
        ChordQuality.ninth,
        ChordQuality.thirteenth
      }),
  minorSeventhFlatFive(
      degrees: [0, 3, 6, 10],
      label: 'm7b5',
      availableTensions: ChordQuality.tonicTensions);

  const ChordType(
      {required this.degrees,
      required this.label,
      this.availableTensions = const {...ChordQuality.values}});

  factory ChordType.fromLabel(String label) {
    for (final type in values) {
      if (type.label == label) return type;
    }
    throw ArgumentError('label is invalid');
  }

  static const triads = [
    major,
    minor,
    diminish,
    augment,
    sus4,
  ];

  final Degrees degrees;
  final String label;
  final Set<ChordQuality> availableTensions;

  bool validate(ChordQualities qualities) =>
      qualities.every((e) => availableTensions.contains(e));

  Notes toNotes(Note root) => degrees.map((i) => root.to(i));
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
    throw ArgumentError('label is invalid');
  }

  factory ChordQuality.fromDegree(Degree degree) {
    for (final quality in values) {
      if (quality.degree == degree) return quality;
    }
    throw ArgumentError('degree is invalid');
  }

  static const tonicTensions = {
    ChordQuality.ninth,
    ChordQuality.eleventh,
    ChordQuality.thirteenth,
  };

  static const normalTensions = {
    ChordQuality.sixth,
    ChordQuality.seventh,
    ChordQuality.majorSeventh,
  };

  final Degree degree;
  final String label;
  final bool combinable;

  Note toNote(Note root) => root.to(degree);
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

  static ChordQualities? fromTypeAndNotes({
    required ChordType type,
    required Note root,
    required Notes notes,
  }) {
    try {
      final indexes = notes.map((e) => root.positiveDegreeTo(e)).toSet()
        ..removeAll(type.degrees);
      final degrees = indexes.map((e) => e < 9 ? e + 12 : e);
      final values = degrees.map(ChordQuality.fromDegree).toSet();
      return ChordQualities(values);
    } catch (e) {
      return null;
    }
  }

  static final empty = ChordQualities(const {});

  final Set<ChordQuality> values;
  late final String label = _label();

  @override
  Iterator<ChordQuality> get iterator => values.iterator;

  @override
  bool operator ==(Object other) {
    if (other is ChordQualities) {
      return setEquals(values.toSet(), values.toSet());
    }
    return false;
  }

  @override
  int get hashCode => values.hashCode;

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
    ChordQualities? qualities,
  })  : assert(notes.contains(root)),
        qualities = qualities ?? ChordQualities.empty,
        type = _fromNotes(notes, root)
            .firstWhere((record) =>
                record.qualities == (qualities ?? ChordQualities.empty))
            .type;

  Chord.fromType(
      {required this.type, required this.root, ChordQualities? qualities})
      : assert(
          qualities == null || type.validate(qualities),
          'chordType: $type, availableTensions: ${type.availableTensions}, tensions: $qualities',
        ),
        qualities = qualities ?? ChordQualities.empty,
        notes = [
          ...type.degrees.map((e) => root.to(e)),
          ...?qualities?.map((e) => root.to(e.degree)),
        ];

  factory Chord.fromLabel(String chord) {
    //TODO 全てのコードタイプに対応させる。現在は評価実験に出てくるもののみ
    final exp = RegExp(
        r'([A-G][#b]?)((?:m|dim|dim7|aug|sus4|sus2|m7b5)?)((?:6|7|M7|add9)?)');
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError('label is invalid');

    try {
      final root = Note.fromLabel(match.group(1)!);
      final type = ChordType.fromLabel(match.group(2) ?? '');
      final qualities = ChordQualities.fromLabel(match.group(3) ?? '');

      return Chord.fromType(type: type, root: root, qualities: qualities);
    } catch (e) {
      rethrow;
    }
  }

  //TODO impl this
  //コードは一意に定まらなかったり、該当するものがなかったりするため、factoryにはできない
  //探索木に代わるもの
  static Iterable<Chord> fromNotes(Notes notes) {
    final chords = <Chord>[];

    for (final root in notes) {
      for (final record in _fromNotes(notes, root)) {
        chords.add(Chord.fromType(
          type: record.type,
          root: root,
          qualities: record.qualities,
        ));
      }
    }

    return chords;
  }

  static Iterable<({ChordType type, ChordQualities qualities})> _fromNotes(
      Notes notes, Note root) {
    final degrees = notes.map((e) => root.positiveDegreeTo(e));
    return ChordType.values
        .where((type) => type.degrees.every((e) => degrees.contains(e)))
        .map((type) => (
              type: type,
              qualities: ChordQualities.fromTypeAndNotes(
                  type: type, root: root, notes: notes)
            ))
        .whereType<({ChordType type, ChordQualities qualities})>()
        .where((record) => record.type.validate(record.qualities));
  }

  static const noChordLabel = '***';

  late final String label = root.label + type.label + qualities.label;
  late final PCP pcp = PCP.fromNotes(notes);

  final Note root;
  final ChordType type;

  final Notes notes;
  final ChordQualities qualities;

  @override
  bool operator ==(Object other) {
    if (other is Chord) {
      return root == other.root &&
          type == other.type &&
          setEquals(notes.toSet(), other.notes.toSet()) &&
          qualities == other.qualities;
    }
    return false;
  }

  @override
  int get hashCode =>
      root.hashCode ^ type.hashCode ^ notes.hashCode ^ qualities.hashCode;

  @override
  String toString() => label;
}
