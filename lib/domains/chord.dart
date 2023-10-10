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
//m7b5に関しては、実質dim + seventhであるので、条件分岐をする前提ならこちらに含めなくて良い
//TODO 追加予定
//omit5
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
    },
  ),
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
    },
    isOperation: true,
  ),
  sus4(
    degrees: [0, 5, 7],
    label: 'sus4',
    availableTensions: {
      ...ChordQuality.normalTensions,
      ChordQuality.ninth,
      ChordQuality.thirteenth
    },
    isOperation: true,
  ),
  minorSeventhFlatFive(
    degrees: [0, 3, 6, 10],
    label: 'm7b5',
    availableTensions: ChordQuality.tonicTensions,
  );

  const ChordType({
    required this.degrees,
    required this.label,
    this.availableTensions = const {...ChordQuality.values},
    this.isOperation = false,
  });

  factory ChordType.parse(String label) {
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
  final bool isOperation; //操作系を表すコードタイプはテンションとコードタイプの表記が逆転する

  bool validate(ChordQualities qualities) =>
      qualities.every((e) => availableTensions.contains(e));

  Notes toNotes(Note root) => degrees.map((i) => root.transpose(i));
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

  factory ChordQuality.parse(String label) {
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

  Note toNote(Note root) => root.transpose(degree);
}

@immutable
class ChordQualities extends Iterable<ChordQuality> {
  ChordQualities(this.values)
      : assert(values.where((e) => !e.combinable).length <= 1);

  factory ChordQualities.parse(String label) {
    //TODO 全てのQualitiesに対応させる。現在は評価実験に出てくるもののみ
    if (label.isEmpty) return empty;
    label = label.replaceAll('add', '');
    return ChordQualities({ChordQuality.parse(label)});
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
  static final seventh = ChordQualities(const {ChordQuality.seventh});
  static final majorSeventh = ChordQualities(const {ChordQuality.majorSeventh});

  final Set<ChordQuality> values;
  late final String label = _label();

  @override
  Iterator<ChordQuality> get iterator => values.iterator;

  @override
  bool operator ==(Object other) {
    if (other is ChordQualities) {
      return setEquals(values.toSet(), other.values.toSet());
    }
    return false;
  }

  @override
  int get hashCode => values.fold(0, (value, e) => value ^ e.hashCode);

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
class ChordBase {
  ChordBase({
    required this.type,
    ChordQualities? qualities,
  }) : qualities = qualities ?? ChordQualities.empty;

  factory ChordBase.parse(String chord) {
    //TODO 全てに対応できるようにする
    final exp = RegExp(
        r'^((?:m|dim7|dim|aug|m7b5)?)((?:6|7|M7)?)((?:sus4|sus2)?)((?:add9|aad11|add13)?)$');
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError('invalid in ChordBase: $chord');

    try {
      final type = ChordType.parse(
        match.group(1)!.isNotEmpty ? match.group(1)! : match.group(3)!,
      );
      final qualities = ChordQualities.parse(
        match.group(2)! + match.group(4)!,
      );

      return ChordBase(type: type, qualities: qualities);
    } catch (e) {
      rethrow;
    }
  }

  final ChordType type;
  final ChordQualities qualities;

  bool baseEqual(ChordBase other) {
    return type == other.type && qualities == other.qualities;
  }

  Chord toChord(Note root) =>
      Chord.fromType(type: type, root: root, qualities: qualities);

  DegreeChord toDegreeChord(DegreeName degreeName) =>
      DegreeChord(degreeName, type: type, qualities: qualities);

  @override
  String toString() {
    if (type.isOperation) {
      return qualities.label + type.label;
    }
    return type.label + qualities.label;
  }

  @override
  bool operator ==(Object other) {
    if (other is ChordBase) {
      return baseEqual(other);
    }
    return false;
  }

  @override
  int get hashCode => type.hashCode ^ qualities.hashCode;
}

@immutable
class DegreeChord extends ChordBase implements Transposable<DegreeChord> {
  DegreeChord(this.degreeName, {required super.type, super.qualities});

  factory DegreeChord.parse(String chord) {
    final exp = RegExp(r'^([#b]?(?:VII|VI|V|IV|I{0,3}|))(.*?)$');
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError('invalid DegreeChord: $chord');

    try {
      final degreeName = DegreeName.parse(match.group(1)!);
      return ChordBase.parse(match.group(2)!).toDegreeChord(degreeName);
    } catch (e) {
      rethrow;
    }
  }

  final DegreeName degreeName;

  @override
  bool operator ==(Object other) {
    if (other is DegreeChord) {
      return super == this && degreeName == other.degreeName;
    }
    return false;
  }

  @override
  int get hashCode => super.hashCode ^ degreeName.hashCode;

  @override
  String toString() => degreeName.label + super.toString();

  @override
  DegreeChord transpose(int degree) {
    return DegreeChord(
      degreeName.transpose(degree),
      type: type,
      qualities: qualities,
    );
  }

  Chord toChordFromKey(Note key) => Chord.fromType(
        type: type,
        root: key.transpose(degreeName.index),
        qualities: qualities,
      );
}

@immutable
class Chord extends ChordBase {
  Chord({
    required this.notes,
    required this.root,
    super.qualities,
  })  : assert(notes.contains(root)),
        super(
            type: _fromNotes(notes, root)
                .firstWhere((record) =>
                    record.qualities == (qualities ?? ChordQualities.empty))
                .type);

  Chord.fromType({required super.type, required this.root, super.qualities})
      : assert(
          qualities == null || type.validate(qualities),
          'chordType: $type, availableTensions: ${type.availableTensions}, tensions: $qualities',
        ),
        notes = [
          ...type.degrees.map((e) => root.transpose(e)),
          ...?qualities?.map((e) => root.transpose(e.degree)),
        ];

  factory Chord.parse(String chord) {
    final exp = RegExp(r'^([A-G][#b]?)(.*?)$');
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError('invalid in Chord: $chord');

    try {
      final root = Note.parse(match.group(1)!);
      return ChordBase.parse(match.group(2)!).toChord(root);
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
              selectingQualities: ChordQualities.fromTypeAndNotes(
                  type: type, root: root, notes: notes)
            ))
        .whereType<({ChordType type, ChordQualities qualities})>()
        .where((record) => record.type.validate(record.qualities));
  }

  late final PCP pcp = PCP.fromNotes(notes);

  final Note root;
  final Notes notes;

  @override
  bool operator ==(Object other) {
    if (other is Chord) {
      return super == this &&
          root == other.root &&
          setEquals(notes.toSet(), other.notes.toSet());
    }
    return false;
  }

  @override
  int get hashCode =>
      super.hashCode ^
      root.hashCode ^
      notes.fold(0, (value, e) => value ^ e.hashCode);

  @override
  String toString() => root.toString() + super.toString();
}
