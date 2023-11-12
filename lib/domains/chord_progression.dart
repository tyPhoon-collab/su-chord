import 'dart:math';

import '../utils/table.dart';
import 'annotation.dart';
import 'chord.dart';
import 'equal_temperament.dart';

class ChordProgression<T extends ChordBase<T>> extends Iterable<ChordCell<T>>
    implements Transposable<ChordProgression> {
  const ChordProgression(this._values);

  static ChordProgression<Chord> chordEmpty() =>
      const ChordProgression<Chord>([]);

  static ChordProgression<DegreeChord> degreeChordEmpty() =>
      const ChordProgression<DegreeChord>([]);

  static ChordProgression<DegreeChord> fromDegreeChordRow(Row row) {
    return ChordProgression(row
        .map((e) => ChordCell<DegreeChord>(chord: DegreeChord.parse(e)))
        .toList());
  }

  static ChordProgression<Chord> fromChordRow(
    Row row, {
    bool ignoreNotParsable = false,
    List<Time>? times,
  }) {
    assert(times == null || row.length == times.length);

    final chords = <ChordCell<Chord>>[];
    for (int i = 0; i < row.length; i++) {
      final value = row[i];
      Chord? chord;
      try {
        chord = Chord.parse(value);
      } catch (e) {
        if (!ignoreNotParsable) rethrow;
      }
      chords.add(ChordCell(
        chord: chord,
        time: times?[i],
      ));
    }
    return ChordProgression(chords);
  }

  static const chordSeparator = '->';

  final List<ChordCell<T>> _values;

  @override
  Iterator<ChordCell<T>> get iterator => _values.iterator;

  @override
  String toString() => _values.isEmpty
      ? 'No Chords'
      : _values.map((e) => e.toString()).join(chordSeparator);

  String toDetailString() => _values.isEmpty
      ? 'No Chords'
      : _values.map((e) => e.toDetailString()).join(chordSeparator);

  List<String> toCSVRow() => _values.map((e) => e.toString()).toList();

  void add(ChordCell<T> chord) {
    assert(_values.isEmpty ||
        (_values.last.time?.end ?? 0) <= (chord.time?.start ?? 0));
    _values.add(chord);
  }

  double similarity(ChordProgression<T> other) {
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

  ChordProgression<T> cut(int start, [int? end]) =>
      ChordProgression(_values.sublist(start, end));

  ChordProgression<T> simplify() {
    if (_values.isEmpty) return this;

    final cells = [_values.first];

    for (final value in _values.skip(1)) {
      final last = cells.last;
      if (last.chord != value.chord) {
        cells.add(value);
      } else {
        cells[cells.length - 1] = last.copyWith(
          time: last.time?.copyWith(
            end: value.time?.end,
          ),
        );
      }
    }

    return ChordProgression(cells);
  }

  ChordProgression<T> nonNulls() {
    return ChordProgression(_values.where((e) => e.chord != null).toList());
  }

  @override
  ChordProgression<T> transpose(int degree) =>
      ChordProgression(_values.map((e) => e.transpose(degree)).toList());

  ChordProgression<Chord> toChord(Note key) => ChordProgression<Chord>(_values
      .cast<ChordCell<DegreeChord>>()
      .map((e) => ChordCell<Chord>(chord: e.chord?.toChordFromKey(key)))
      .toList());

  List<T?> toChordList() => map((e) => e.chord).toList();
}
