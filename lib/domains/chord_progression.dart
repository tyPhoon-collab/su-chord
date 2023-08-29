import 'dart:math';

import 'chord.dart';

class ProgressionBase<T extends ChordBase> extends Iterable<T?> {
  ProgressionBase(this._values);

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

  void add(T? chord) {
    _values.add(chord);
  }
}

class DegreeChordProgression extends ProgressionBase<DegreeChord> {
  DegreeChordProgression(super.values);

  DegreeChordProgression.empty() : super([]);

  factory DegreeChordProgression.fromCSVRow(List<String> row) {
    return DegreeChordProgression(
        row.map((e) => DegreeChord.parse(e)).toList());
  }
}

class ChordProgression extends ProgressionBase<Chord> {
  ChordProgression(super._values);

  ChordProgression.empty() : super([]);

  factory ChordProgression.fromCSVRow(List<String> row) {
    throw UnimplementedError();
  }

  double consistencyRate(ChordProgression other) {
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

  ChordProgression cut(int start, [int? end]) {
    return ChordProgression(_values.sublist(start, end));
  }
}
