import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../utils/score.dart';
import 'annotation.dart';
import 'chroma.dart';
import 'equal_temperament.dart';

///基本的なコードタイプを列挙する
///度数とラベル、各コードタイプにおいて、有効なテンションの情報を保持している
///テンションなどはChordクラスで管理する
///dim7, m7b5もこちらに含める
//m7b5に関しては、実質dim + seventhであるので、条件分岐をする前提ならこちらに含めなくて良い
enum ChordType {
  major.all({_r, NamedDegree.M3, NamedDegree.P5}, label: ''),
  minor(
    {_r, NamedDegree.m3, NamedDegree.P5},
    label: 'm',
    availableTensions: {
      ...ChordTension.normalTensions,
      ...ChordTension.tonicTensions
    },
  ),
  diminish(
    {_r, NamedDegree.m3, NamedDegree.dim5},
    label: 'dim',
    availableTensions: {},
  ),
  diminish7(
    {_r, NamedDegree.m3, NamedDegree.dim5, NamedDegree.M6},
    label: 'dim7',
    availableTensions: {},
  ),
  augment(
    {_r, NamedDegree.M3, NamedDegree.aug5},
    label: 'aug',
    availableTensions: {ChordTension.seventh},
  ),
  sus2(
    {_r, NamedDegree.M2, NamedDegree.P5},
    label: 'sus2',
    availableTensions: {
      ...ChordTension.normalTensions,
      ChordTension.eleventh,
      ChordTension.thirteenth
    },
    isOperation: true,
  ),
  sus4(
    {_r, NamedDegree.P4, NamedDegree.P5},
    label: 'sus4',
    availableTensions: {
      ...ChordTension.normalTensions,
      ChordTension.ninth,
      ChordTension.thirteenth
    },
    isOperation: true,
  ),
  minorSeventhFlatFive(
    {_r, NamedDegree.m3, NamedDegree.dim5, NamedDegree.m7},
    label: 'm7b5',
    availableTensions: ChordTension.tonicTensions,
  );

  const ChordType(
    this.degrees, {
    required this.label,
    required this.availableTensions,
    this.isOperation = false,
  });

  const ChordType.all(
    this.degrees, {
    required this.label,
  })  : availableTensions = const {...ChordTension.values},
        isOperation = false;

  factory ChordType.parse(String label) {
    for (final type in values) {
      if (type.label == label) return type;
    }
    throw ArgumentError('Invalid label in ChordType $label');
  }

  static const _r = NamedDegree.P1; //root alias

  static const triads = [
    major,
    minor,
    diminish,
    augment,
    sus4,
  ];

  final Set<NamedDegree> degrees;
  final String label;
  final Set<ChordTension> availableTensions;
  final bool isOperation; //操作系を表すコードタイプはテンションとコードタイプの表記が逆転する

  bool validate(ChordTensions tensions) =>
      tensions.every((e) => availableTensions.contains(e));

  Notes toNotes(Note root) =>
      degrees.map((d) => root.transpose(d.degreeIndex)).toList();
}

///コードタイプに追加で付与されうる音
///combinableがfalse同士は、どんな状況であっても音楽理論的に共存し得ない
///これらの管理はChordQualitiesが行う
enum ChordTension {
  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  sixth(NamedDegree.M6, label: '6', combinable: false),
  seventh(NamedDegree.m7, label: '7', combinable: false),
  majorSeventh(NamedDegree.M7, label: 'M7', combinable: false),
  flatNinth(NamedDegree.b9, label: 'b9'),
  ninth(NamedDegree.M9, label: '9'),
  sharpNinth(NamedDegree.s9, label: '#9'),
  eleventh(NamedDegree.M11, label: '11'),
  sharpEleventh(NamedDegree.s11, label: '#11'),
  flatThirteenth(NamedDegree.b13, label: 'b13'),
  thirteenth(NamedDegree.M13, label: '13');

  const ChordTension(
    this.degree, {
    required this.label,
    this.combinable = true,
  });

  factory ChordTension.parse(String label) {
    for (final quality in values) {
      if (quality.label == label) return quality;
    }
    throw ArgumentError('Invalid label in ChordQuality $label');
  }

  factory ChordTension.fromDegreeIndex(int degreeIndex) {
    for (final quality in values) {
      if (quality.degree.degreeIndex == degreeIndex) return quality;
    }
    throw ArgumentError('Invalid degree $degreeIndex');
  }

  static const tonicTensions = {
    ChordTension.ninth,
    ChordTension.eleventh,
    ChordTension.thirteenth,
  };

  static const normalTensions = {
    ChordTension.sixth,
    ChordTension.seventh,
    ChordTension.majorSeventh,
  };

  final NamedDegree degree;
  final String label;
  final bool combinable;

  Note toNote(Note root) => root.transpose(degree.degreeIndex);
}

@immutable
final class ChordTensions extends Iterable<ChordTension> {
  ChordTensions(this.values)
      : assert(values.where((e) => !e.combinable).length <= 1);

  factory ChordTensions.parse(String label) {
    final parts = label.split('add');

    assert(parts.length <= 2);

    final qualities = <ChordTension>{};

    qualities.addAll(
      switch (parts[0]) {
        '' => [],
        '9' => [ChordTension.seventh, ChordTension.ninth],
        '11' => [
            ChordTension.seventh,
            ChordTension.ninth,
            ChordTension.eleventh
          ],
        '13' => [
            ChordTension.seventh,
            ChordTension.ninth,
            ChordTension.eleventh,
            ChordTension.thirteenth
          ],
        'M9' => [ChordTension.majorSeventh, ChordTension.ninth],
        'M11' => [
            ChordTension.majorSeventh,
            ChordTension.ninth,
            ChordTension.eleventh
          ],
        'M13' => [
            ChordTension.majorSeventh,
            ChordTension.ninth,
            ChordTension.eleventh,
            ChordTension.thirteenth
          ],
        _ => [ChordTension.parse(parts[0])],
      },
    );
    if (parts.length == 2) {
      qualities.addAll(parts[1]
          .split(',')
          .where((e) => e.isNotEmpty)
          .map(ChordTension.parse));
    }
    return ChordTensions(qualities);
  }

  static ChordTensions? fromTypeAndNotes({
    required ChordType type,
    required Note root,
    required Notes notes,
  }) {
    try {
      final indexes = notes.map((e) => root.positiveDegreeIndexTo(e)).toSet()
        ..removeAll(type.degrees.map((e) => e.degreeIndex).toSet());
      final degrees = indexes.map((e) => e < 9 ? e + 12 : e);
      final values = degrees.map(ChordTension.fromDegreeIndex).toSet();
      return ChordTensions(values);
    } catch (e) {
      return null;
    }
  }

  static final empty = ChordTensions(const {});
  static final seventh = ChordTensions(const {ChordTension.seventh});
  static final majorSeventh = ChordTensions(const {ChordTension.majorSeventh});

  final Set<ChordTension> values;
  late final String label = _label();

  @override
  Iterator<ChordTension> get iterator => values.iterator;

  @override
  bool operator ==(Object other) {
    if (other is ChordTensions) {
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
class ChordBase<T> implements Transposable<T> {
  ChordBase({
    required this.type,
    ChordTensions? tensions,
  }) : tensions = tensions ?? ChordTensions.empty;

  ChordBase.of(ChordBase base)
      : type = base.type,
        tensions = base.tensions;

  factory ChordBase.parse(String chord) {
    //TODO 全てに対応できるようにする
    final exp = RegExp(
        r'^((?:m|dim7|dim|aug|m7b5)?)((?:6|7|9|11|13|M7|M9|M11|M13)?)((?:sus4|sus2)?)((?:add9|aad11|add13)?)$');
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError('invalid in ChordBase: $chord');

    try {
      final type = ChordType.parse(
        match.group(1)!.isNotEmpty ? match.group(1)! : match.group(3)!,
      );
      final qualities = ChordTensions.parse(
        match.group(2)! + match.group(4)!,
      );

      return ChordBase(type: type, tensions: qualities);
    } catch (e) {
      rethrow;
    }
  }

  factory ChordBase.fromNotes(
    Notes notes,
    Note root,
  ) {
    try {
      final degrees = notes.map((e) => root.positiveDegreeIndexTo(e));
      return ChordBase.of(
        ChordType.values
            .where((type) => type.degrees
                .map((e) => e.degreeIndex)
                .every((e) => degrees.contains(e)))
            .map((type) => ChordBase(
                  type: type,
                  tensions: ChordTensions.fromTypeAndNotes(
                    type: type,
                    root: root,
                    notes: notes,
                  ),
                ))
            .where((base) => base.type.validate(base.tensions))
            .first,
      );
    } catch (e) {
      rethrow;
    }
  }

  final ChordType type;
  final ChordTensions tensions;

  bool baseEqual(ChordBase other) {
    return type == other.type && tensions == other.tensions;
  }

  Chord toChord(Note root) =>
      Chord.fromType(type: type, root: root, tensions: tensions);

  DegreeChord toDegreeChord(DegreeName degreeName) =>
      DegreeChord(degreeName, type: type, tensions: tensions);

  @override
  String toString() {
    if (type.isOperation) {
      return tensions.label + type.label;
    }
    return type.label + tensions.label;
  }

  @override
  bool operator ==(Object other) {
    if (other is ChordBase) {
      return baseEqual(other);
    }
    return false;
  }

  @override
  int get hashCode => type.hashCode ^ tensions.hashCode;

  @override
  T transpose(int degree) {
    throw UnimplementedError();
  }
}

@immutable
final class DegreeChord extends ChordBase<DegreeChord> {
  DegreeChord(this.degreeName, {required super.type, super.tensions});

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
      tensions: tensions,
    );
  }

  Chord toChordFromKey(Note key) => Chord.fromType(
        type: type,
        root: key.transpose(degreeName.index),
        tensions: tensions,
      );
}

@immutable
final class Chord extends ChordBase<Chord> {
  factory Chord.fromNotesAndRoot({
    required Notes notes,
    required Note root,
  }) {
    assert(notes.contains(root), 'root must be contained in notes');

    try {
      final base = ChordBase.fromNotes(notes, root);
      return Chord.fromType(
        type: base.type,
        root: root,
        tensions: base.tensions,
      );
    } catch (e) {
      rethrow;
    }
  }

  Chord.fromType({required super.type, required this.root, super.tensions})
      : assert(
          tensions == null || type.validate(tensions),
          'chordType: $type, availableTensions: ${type.availableTensions}, tensions: $tensions',
        ),
        notes = List.unmodifiable([
          ...type.degrees.map((e) => root.transpose(e.degreeIndex)),
          ...?tensions?.map((e) => root.transpose(e.degree.degreeIndex)),
        ]);

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

  //コードは一意に定まらなかったり、該当するものがなかったりするため、factoryにはできない
  static Iterable<Chord> fromNotes(Notes notes) {
    final chords = <Chord>[];

    for (final root in notes) {
      try {
        final mayBeChord = Chord.fromNotesAndRoot(notes: notes, root: root);
        chords.add(mayBeChord);
      } catch (_) {}
    }

    return chords;
  }

  static final C = Chord.parse('C');
  static final D = Chord.parse('D');
  static final E = Chord.parse('E');
  static final F = Chord.parse('F');
  static final G = Chord.parse('G');
  static final A = Chord.parse('A');
  static final B = Chord.parse('B');

  late final PCP unitPCP = PCP.fromNotes(notes);

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

  @override
  Chord transpose(int degree) => Chord.fromType(
        type: type,
        root: root.transpose(degree),
        tensions: tensions,
      );
}

@immutable
class ChordCell<T extends ChordBase<T>> implements Transposable<ChordCell<T>> {
  const ChordCell({
    this.chord,
    this.time,
  });

  static const noChordLabel = '***';

  final T? chord;
  final Time? time;

  @override
  String toString() => chord?.toString() ?? noChordLabel;

  String toDetailString() =>
      '$chord${time != null ? '(${time!.start.toStringAsFixed(2)}-${time!.end.toStringAsFixed(2)})' : ''}';

  @override
  ChordCell<T> transpose(int degree) =>
      ChordCell(chord: chord?.transpose(degree), time: time);

  @override
  bool operator ==(Object other) {
    return other is ChordCell<T> && chord == other.chord && time == other.time;
  }

  @override
  int get hashCode => chord.hashCode ^ time.hashCode;

  ChordCell<T> copyWith({T? chord, Time? time}) {
    return ChordCell<T>(
      chord: chord ?? this.chord,
      time: time ?? this.time,
    );
  }

  ///自身が正解だとして、オーバーラップスコアを算出する
  FScore overlapScore(ChordCell<T> other, {Time? limitation}) {
    assert(this.time != null && other.time != null);

    if (!time!.overlapStatus(other.time!).isOverlapping) {
      return FScore.zero;
    }

    final isCorrect = chord == other.chord;

    final min = limitation?.start ?? double.negativeInfinity;
    final max = limitation?.end ?? double.infinity;

    final start = time!.start.clamp(min, max);
    final end = time!.end.clamp(min, max);
    final otherStart = other.time!.start.clamp(min, max);
    final otherEnd = other.time!.end.clamp(min, max);

    double truthPositiveTime = 0;
    double falsePositiveTime = 0;
    double falseNegativeTime = 0;

    void addPositive(double value) {
      if (isCorrect) {
        truthPositiveTime += value;
      } else {
        falsePositiveTime += value;
      }
    }

    if (otherStart < start) {
      falsePositiveTime += start - otherStart;

      if (otherEnd < end) {
        addPositive(otherEnd - start);
        falseNegativeTime += end - otherEnd;
      } else {
        addPositive(time!.duration);
        falsePositiveTime += otherEnd - end;
      }
    } else {
      falseNegativeTime += otherStart - start;
      if (otherEnd < end) {
        addPositive(other.time!.duration);
        falseNegativeTime += end - otherEnd;
      } else {
        addPositive(end - otherStart);
        falsePositiveTime += otherEnd - end;
      }
    }

    return FScore(truthPositiveTime, falsePositiveTime, falseNegativeTime);
  }
}

class MultiChordCell<T extends ChordBase<T>> extends ChordCell<T> {
  const MultiChordCell({
    this.chords = const [],
    super.chord,
    super.time,
  });

  MultiChordCell.first(
    this.chords, {
    super.time,
  }) : super(chord: chords.firstOrNull);

  final List<T> chords;

  @override
  MultiChordCell<T> transpose(int degree) => MultiChordCell(
        chords: chords.map((e) => e.transpose(degree)).toList(),
        chord: chord?.transpose(degree),
        time: time,
      );

  @override
  MultiChordCell<T> copyWith({List<T>? chords, T? chord, Time? time}) {
    return MultiChordCell<T>(
      chords: chords ?? this.chords,
      chord: chord ?? this.chord,
      time: time ?? this.time,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is MultiChordCell<T> &&
        listEquals(chords, other.chords) &&
        chord == other.chord &&
        time == other.time;
  }

  @override
  int get hashCode => chords.hashCode ^ super.hashCode;
}
