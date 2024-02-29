import 'dart:math';

import '../utils/score.dart';
import '../utils/table.dart';
import 'annotation.dart';
import 'chord_cell.dart';

class ChordProgression<T extends ChordBase> extends Iterable<ChordCell<T>>
    implements Transposable {
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
    assert(
      times == null || row.length == times.length,
      'row: $row, times: $times',
    );

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
  static const noChordLabel = 'No Chords';
  static const header = ['label', 'start', 'end'];

  final List<ChordCell<T>> _values;

  @override
  Iterator<ChordCell<T>> get iterator => _values.iterator;

  ChordCell<T> operator [](int index) => _values[index];

  void add(ChordCell<T> chord) {
    assert(_values.isEmpty ||
        (_values.last.time?.end ?? 0) <= (chord.time?.start ?? 0));
    _values.add(chord);
  }

  double similarity(ChordProgression<T> other) {
    final values = toChordList();
    final otherValues = other.toChordList();
    final minLength = min(otherValues.length, length);
    final maxLength = max(otherValues.length, length);
    int count = 0;
    for (int i = 0; i < minLength; i++) {
      if (otherValues[i] == values[i]) {
        count++;
      }
    }
    return count / maxLength;
  }

  FScore overlapScore(ChordProgression<T> other) {
    assert(every((e) => e.time != null) && other.every((e) => e.time != null));

    FScore rate = FScore.zero;
    int seekingOtherIndex = 0;
    double seek = double.negativeInfinity;

    Time createLimitation(double start) {
      final limitation = Time(seek, start);
      seek = start;
      return limitation;
    }

    for (int i = 0; i < length && seekingOtherIndex < other.length;) {
      final value = _values[i];
      final another = other[seekingOtherIndex];

      final status = value.time!.overlapStatus(another.time!);
      switch (status) {
        case OverlapStatus.overlapping:
          late final Time limitation;
          final nextTime = i + 1 < length ? _values[i + 1].time! : null;
          final nextOtherTime = seekingOtherIndex + 1 < other.length
              ? other[seekingOtherIndex + 1].time!
              : null;

          if (nextTime != null &&
              nextTime.overlapStatus(another.time!).isOverlapping) {
            limitation = createLimitation(nextTime.start);
            i++;
          } else if (nextOtherTime != null &&
              nextOtherTime.overlapStatus(value.time!).isOverlapping) {
            limitation = createLimitation(nextOtherTime.start);
            seekingOtherIndex++;
          } else {
            limitation = createLimitation(min(
              nextTime?.start ?? double.infinity,
              nextOtherTime?.start ?? double.infinity,
            ));
            i++;
          }

          rate += value.overlapScore(another, limitation: limitation);
        case OverlapStatus.anotherIsLate:
          i++;
        case OverlapStatus.anotherIsFast:
          seekingOtherIndex++;
      }
    }

    return rate;
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

  @override
  String toString() => _values.isEmpty
      ? noChordLabel
      : _values.map((e) => e.toString()).join(chordSeparator);

  String toDetailString() => _values.isEmpty
      ? noChordLabel
      : _values.map((e) => e.toDetailString()).join(chordSeparator);

  Row toRow() => _values.map((e) => e.toString()).toList();

  Table toTable() => Table(
        map((e) => [
              e.chord.toString(),
              e.time!.start.toString(),
              e.time!.end.toString(),
            ]).toList(),
        header: header,
      );
}
