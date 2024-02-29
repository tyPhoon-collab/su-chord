import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import 'chroma.dart';
import 'equal_temperament.dart';
import 'musical_label.dart';

export 'equal_temperament.dart';

@immutable
base class ChordBase implements Transposable {
  const ChordBase({
    required this.type,
    this.tensions,
    this.operation,
  });

  factory ChordBase.parse(String chord) {
    //現状の対応のみ。完全なパーサーは難しい
    final exp = RegExp(chordPattern);

    final match = exp.firstMatch(chord);

    if (match == null) {
      throw ArgumentError('invalid in ChordBase: $chord');
    }

    try {
      final type = ChordType.parse(match.group(1) ?? match.group(3) ?? '');

      final tensions =
          ChordTensions.parse((match.group(2) ?? '') + (match.group(4) ?? ''));

      if (!(tensions?.validate() ?? true)) {
        throw ArgumentError('tensions is not validate');
      }

      final operation = ChordOperation.parse(match.group(5) ?? '');

      if (!type.validate(tensions, operation)) {
        throw ArgumentError(
            'tensions and operation combination is not validate');
      }
      return ChordBase(type: type, tensions: tensions, operation: operation);
    } catch (e) {
      rethrow;
    }
  }

  static final chordPattern = _buildChordPattern();

  static String _buildChordPattern() {
    final type =
        "((?:${ChordType.patterns.expand((e) => e.label.all.map((e) => RegExp.escape(e))).where((e) => e.isNotEmpty).toSet().join('|')}))?";
    const tensions = '((?:6|7|9|11|13|M7|M9|M11|M13))?';
    final sus = "((?:${ChordType.sus.expand((e) => e.label.all).join('|')}))?";
    const addition = '((?:add9|add11|add13))?';
    const operation = r'(\(omit5\))?';

    return '^$type$tensions$sus$addition$operation' r'$';
  }

  final ChordType type;
  final ChordTensions? tensions;
  final ChordOperation? operation;

  bool baseEqual(ChordBase other) {
    return type == other.type &&
        tensions == other.tensions &&
        operation == other.operation;
  }

  Chord toChord(Note root) => Chord.fromType(
        type: type,
        root: root,
        tensions: tensions,
        operation: operation,
      );

  DegreeChord toDegreeChord(DegreeName degreeName) => DegreeChord(
        degreeName,
        type: type,
        tensions: tensions,
        operation: operation,
      );

  @override
  String toString() {
    final tensionsString = tensions?.toString() ?? '';
    final baseString = ChordType.sus.contains(type)
        ? '$tensionsString${type.label}'
        : '${type.label}$tensionsString';
    final operationString = operation?.label ?? '';
    return '$baseString$operationString';
  }

  @override
  bool operator ==(Object other) {
    if (other is ChordBase) {
      return baseEqual(other);
    }
    return false;
  }

  @override
  int get hashCode => type.hashCode ^ tensions.hashCode ^ operation.hashCode;

  @override
  Transposable transpose(int degree) {
    throw UnimplementedError();
  }
}

@immutable
final class DegreeChord extends ChordBase {
  const DegreeChord(
    this.degreeName, {
    required super.type,
    super.tensions,
    super.operation,
  });

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
  DegreeChord transpose(int degree) => DegreeChord(
        degreeName.transpose(degree),
        type: type,
        tensions: tensions,
      );

  Chord toChordFromKey(Note key) => Chord.fromType(
        type: type,
        root: key.transpose(degreeName.index),
        tensions: tensions,
      );
}

@immutable
final class Chord extends ChordBase {
  Chord.fromType({
    required super.type,
    required this.root,
    super.tensions,
    super.operation,
  })  : assert(
          type.validate(tensions, operation),
          'chordType: $type, availableTensions: ${type.availableTensions}, tensions: $tensions',
        ),
        notes = List.unmodifiable([
          ...type.toNotes(root, operation),
          ...?tensions?.toNotes(root),
        ]);

  factory Chord.parse(String chord) {
    final exp = RegExp(
      r'^([A-G]['
      '${Accidental.values.map((e) => e.label.all).join()}'
      r']?)(.*?)$',
    );
    final match = exp.firstMatch(chord);

    if (match == null) throw ArgumentError('invalid in Chord: $chord');

    try {
      final root = Note.parse(match.group(1)!);
      return ChordBase.parse(match.group(2)!).toChord(root);
    } catch (e) {
      rethrow;
    }
  }

  static final C = Chord.parse('C');
  static final D = Chord.parse('D');
  static final E = Chord.parse('E');
  static final F = Chord.parse('F');
  static final G = Chord.parse('G');
  static final A = Chord.parse('A');
  static final B = Chord.parse('B');

  late final PCP unitPCP = PCP.fromNotes(notes);
  late final Set<int> noteIndexes = notes.map((e) => e.noteIndex).toSet();

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
        operation: operation,
      );
}

typedef _D = NamedDegree;

enum ChordOperation {
  omit5('(omit5)');

  const ChordOperation(this.label);

  final String label;

  Set<NamedDegree> call(Iterable<NamedDegree> degrees) => switch (this) {
        ChordOperation.omit5 => Set.of(degrees)..remove(_D.P5),
      };

  static ChordOperation? parse(String label) =>
      values.firstWhereOrNull((e) => e.label == label);
}

///基本的なコードタイプの情報を保持している
///dim7, m7b5もこちらに含める
enum ChordType {
  major(
    {_D.P1, _D.M3, _D.P5},
    MusicalLabel(''),
    availableTensions: {...ChordTension.values},
    availableOperations: {ChordOperation.omit5},
  ),
  minor(
    {_D.P1, _D.m3, _D.P5},
    MusicalLabel('m', {L.jazz: '-'}),
    availableTensions: {
      ...ChordTension.normalTensions,
      ...ChordTension.tonicTensions
    },
    availableOperations: {ChordOperation.omit5},
  ),
  diminish(
    {_D.P1, _D.m3, _D.dim5},
    MusicalLabel('dim', {L.jazz: 'o'}),
    availableTensions: {},
  ),
  diminish7(
    {_D.P1, _D.m3, _D.dim5, _D.M6},
    MusicalLabel('dim7', {L.jazz: 'o7'}),
    availableTensions: {},
  ),
  augment(
    {_D.P1, _D.M3, _D.aug5},
    MusicalLabel('aug', {L.jazz: '+'}),
    availableTensions: {ChordTension.seventh},
  ),
  sus2(
    {_D.P1, _D.M2, _D.P5},
    MusicalLabel('sus2'),
    availableTensions: {
      ...ChordTension.normalTensions,
      ChordTension.eleventh,
      ChordTension.thirteenth
    },
  ),
  sus4(
    {_D.P1, _D.P4, _D.P5},
    MusicalLabel('sus4'),
    availableTensions: {
      ...ChordTension.normalTensions,
      ChordTension.ninth,
      ChordTension.thirteenth
    },
  ),
  minorSeventhFlatFive(
    {_D.P1, _D.m3, _D.dim5, _D.m7},
    MusicalLabel('m7b5', {L.verbose: 'm7(♭5)', L.jazz: 'ø'}),
    availableTensions: ChordTension.tonicTensions,
  );

  const ChordType(
    this._degrees,
    this.label, {
    required this.availableTensions,
    this.availableOperations = const {},
  });

  factory ChordType.parse(String label) {
    for (final type in values) {
      if (type.label.all.contains(label)) return type;
    }
    throw ArgumentError('Invalid label in ChordType $label');
  }

  static const triads = [major, minor, diminish, augment, sus4];

  static const patterns = [
    minor,
    major,
    diminish7,
    diminish,
    augment,
    minorSeventhFlatFive
  ];

  static const sus = [sus4, sus2];

  final Set<NamedDegree> _degrees;
  final MusicalLabel label;
  final Set<ChordTension> availableTensions;
  final Set<ChordOperation> availableOperations;

  bool validate(ChordTensions? tensions, ChordOperation? operation) =>
      (tensions?.every((e) => availableTensions.contains(e)) ?? true) &&
      (operation == null || availableOperations.contains(operation));

  Set<NamedDegree> toDegrees([ChordOperation? operation]) =>
      operation == null ? _degrees : operation(_degrees);

  Notes toNotes(Note root, ChordOperation? operation) {
    return toDegrees(operation)
        .map((d) => root.transpose(d.degreeIndex))
        .toList();
  }
}

///コードタイプに追加で付与されうる音
///combinableがfalse同士は、どんな状況であっても音楽理論的に共存し得ない
///これらの管理やラベルのパースはChordQualitiesが行う
enum ChordTension {
  //0  1 2  3 4 5  6 7  8 9 10 11
  //C C# D D# E F F# G G# A A# B
  sixth.basic(NamedDegree.M6, MusicalLabel('6')),
  seventh.basic(NamedDegree.m7, MusicalLabel('7')),
  majorSeventh.basic(
      NamedDegree.M7,
      MusicalLabel(
        'M7',
        {L.verbose: 'maj7', L.jazz: '△7'},
      )),
  flatNinth(NamedDegree.b9, MusicalLabel('b9', {L.verbose: '♭9'})),
  ninth(NamedDegree.M9, MusicalLabel('9')),
  sharpNinth(NamedDegree.s9, MusicalLabel('#9', {L.verbose: '♯9'})),
  eleventh(NamedDegree.M11, MusicalLabel('11')),
  sharpEleventh(NamedDegree.s11, MusicalLabel('#11', {L.verbose: '♯11'})),
  flatThirteenth(NamedDegree.b13, MusicalLabel('b13', {L.verbose: '♭13'})),
  thirteenth(NamedDegree.M13, MusicalLabel('13'));

  const ChordTension(this.degree, this.label) : combinable = true;

  const ChordTension.basic(this.degree, this.label) : combinable = false;

  factory ChordTension.parse(String label) {
    for (final quality in values) {
      if (quality.label.all.contains(label)) return quality;
    }
    throw ArgumentError('Invalid label in ChordQuality $label');
  }

  static const tonicTensions = {ninth, eleventh, thirteenth};
  static const normalTensions = {sixth, seventh, majorSeventh};

  static const ninthTensions = {seventh, ninth};
  static const eleventhTensions = {seventh, ninth, eleventh};
  static const thirteenthTensions = {seventh, ninth, eleventh, thirteenth};

  static const majorNinthTensions = {majorSeventh, ninth};
  static const majorEleventhTensions = {majorSeventh, ninth, eleventh};
  static const majorThirteenthTensions = {
    majorSeventh,
    ninth,
    eleventh,
    thirteenth
  };

  final NamedDegree degree;
  final MusicalLabel label;
  final bool combinable;

  Note toNote(Note root) => root.transpose(degree.degreeIndex);

  @override
  String toString() => label.toString();
}

@immutable
final class ChordTensions extends Iterable<ChordTension> {
  const ChordTensions(this._values);

  static ChordTensions? parse(String label) {
    final parts = label.split('add');

    assert(parts.length <= 2);

    final qualities = <ChordTension>{};
    final tensions = parts[0];

    qualities.addAll(
      switch (tensions) {
        '' => [],
        '9' => ChordTension.ninthTensions,
        '11' => ChordTension.eleventhTensions,
        '13' => ChordTension.thirteenthTensions,
        'M9' => ChordTension.majorNinthTensions,
        'M11' => ChordTension.majorEleventhTensions,
        'M13' => ChordTension.majorThirteenthTensions,
        _ => [ChordTension.parse(tensions)],
      },
    );
    if (parts.length == 2) {
      qualities.addAll(parts[1]
          .split(',')
          .where((e) => e.isNotEmpty)
          .map(ChordTension.parse));
    }
    if (qualities.isEmpty) return null;
    return ChordTensions(qualities);
  }

  static const seventh = ChordTensions({ChordTension.seventh});
  static const majorSeventh = ChordTensions({ChordTension.majorSeventh});

  final Set<ChordTension> _values;

  bool validate() =>
      _values.isNotEmpty && _values.where((e) => !e.combinable).length <= 1;

  Notes toNotes(Note root) => _values.map((e) => e.toNote(root)).toList();

  @override
  Iterator<ChordTension> get iterator => _values.iterator;

  @override
  bool operator ==(Object other) {
    if (other is ChordTensions) {
      return setEquals(_values, other._values);
    }
    return false;
  }

  @override
  int get hashCode => _values.fold(0, (value, e) => value ^ e.hashCode);

  @override
  String toString() {
    //特定のケースは特殊な表記がされる
    if (_match(ChordTension.ninthTensions)) return '9';
    if (_match(ChordTension.eleventhTensions)) return '11';
    if (_match(ChordTension.thirteenthTensions)) return '13';
    if (_match(ChordTension.majorNinthTensions)) return 'M9';
    if (_match(ChordTension.majorEleventhTensions)) return 'M11';
    if (_match(ChordTension.majorThirteenthTensions)) return 'M13';

    final base =
        _values.where((e) => !e.combinable).firstOrNull?.label.toString() ?? '';
    final tensions = _values.where((e) => e.combinable);

    if (tensions.isEmpty) {
      return base;
    } else if (tensions.length == 1) {
      return '${base}add${tensions.first.label}';
    } else {
      return '$base(${tensions.map((e) => e.label).join(",")})';
    }
  }

  bool _match(Set<ChordTension> tensions) => setEquals(_values, tensions);
}
