import 'dart:math';

import 'chord.dart';

class ChordProgression extends Iterable<Chord?> {
  ChordProgression(this._values);

  ChordProgression.empty() : _values = [];

  final List<Chord?> _values;

  @override
  Iterator<Chord?> get iterator => _values.iterator;

  @override
  String toString() =>
      _values.map((e) => e?.label ?? Chord.noChordLabel).join('->');

  List<String> toCSVRow() =>
      _values.map((e) => e?.toString() ?? Chord.noChordLabel).toList();

  void add(Chord? chord) {
    _values.add(chord);
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
}
