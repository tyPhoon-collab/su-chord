import 'dart:math';

import '../utils/table.dart';
import 'chord.dart';
import 'equal_temperament.dart';

abstract class ChordProgressionBase<T extends ChordBase> extends Iterable<T?> {
  ChordProgressionBase(this._values);

  static const noChordLabel = '***';
  static const chordSeparator = '->';

  final List<T?> _values;

  @override
  Iterator<T?> get iterator => _values.iterator;

  @override
  String toString() => _values.isEmpty
      ? 'No Chords'
      : _values.map((e) => e?.toString() ?? noChordLabel).join(chordSeparator);

  List<String> toCSVRow() =>
      _values.map((e) => e?.toString() ?? noChordLabel).toList();

  void add(T? chord) => _values.add(chord);
}

class DegreeChordProgression extends ChordProgressionBase<DegreeChord>
    implements Transposable<DegreeChordProgression> {
  DegreeChordProgression(super.values);

  DegreeChordProgression.empty() : super([]);

  factory DegreeChordProgression.fromCSVRow(List<String> row) {
    return DegreeChordProgression(
        row.map((e) => DegreeChord.parse(e)).toList());
  }

  @override
  DegreeChordProgression transpose(int degree) =>
      DegreeChordProgression(_values.map((e) => e?.transpose(degree)).toList());

  ChordProgression toChords(Note key) =>
      ChordProgression(_values.map((e) => e?.toChordFromKey(key)).toList());
}

class ChordProgression extends ChordProgressionBase<Chord> {
  ChordProgression(super._values);

  ChordProgression.empty() : super([]);

  factory ChordProgression.fromCSVRow(
    Row row, {
    bool ignoreNotParsable = false,
  }) {
    final chords = <Chord?>[];
    for (final value in row) {
      Chord? chord;
      try {
        chord = Chord.parse(value);
      } catch (e) {
        if (!ignoreNotParsable) {
          rethrow;
        }
      }
      chords.add(chord);
    }
    return ChordProgression(chords);
  }

  double similarity(ChordProgression other) {
    final otherValues = other.toList();
    final len = min(otherValues.length, length);
    int count = 0;
    for (int i = 0; i < len; i++) {
      if (otherValues[i] == _values[i]) {
        count++;
      }
    }
    return count / len;
  }

  ChordProgression cut(int start, [int? end]) =>
      ChordProgression(_values.sublist(start, end));

  ChordProgression simplify() {
    Chord? chord;
    return ChordProgression(_values.where((e) {
      final isDifferent = e != chord;
      chord = e;
      return isDifferent;
    }).toList());
  }
}
