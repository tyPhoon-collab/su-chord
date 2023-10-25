import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../utils/histogram.dart';
import 'chord.dart';
import 'equal_temperament.dart';

typedef Magnitude = List<double>;
typedef Magnitudes = List<Magnitude>;
typedef Spectrogram = List<Float64x2List>;

///クロマ同士の計算などの利便化のために、クラス化する
@immutable
class Chroma extends Iterable<double> {
  Chroma(this._values);

  factory Chroma.zero(int length) => Chroma(List.filled(length, 0.0));

  final List<double> _values;

  static final empty = Chroma(const []);

  int get maxIndex {
    var max = _values[0];
    var maxIndex = 0;
    for (var i = 1; i < _values.length; i++) {
      if (_values[i] > max) {
        max = _values[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  double get max => _values[maxIndex];

  late final Iterable<int> maxSortedIndexes =
      _values.sorted((a, b) => b.compareTo(a)).map((e) => _values.indexOf(e));

  late final normalized = l2norm == 0
      ? Chroma.zero(12)
      : Chroma(_values.map((e) => e / l2norm).toList());
  late final l2norm = sqrt(_values.fold(0.0, (sum, e) => sum + e * e));

  double cosineSimilarity(Chroma other) {
    assert(_values.length == other._values.length);
    double sum = 0;
    for (int i = 0; i < _values.length; ++i) {
      sum += normalized[i] * other.normalized[i];
    }
    return sum;
  }

  Chroma shift(int num) {
    if (num == 0) return this;
    final length = _values.length;
    num %= length; // 配列の長さより大きい場合は余りを取る
    final rotated = _values.sublist(length - num)
      ..addAll(_values.sublist(0, length - num));
    return Chroma(rotated);
  }

  Chroma operator +(Chroma other) {
    assert(_values.length == other._values.length,
        'source: ${_values.length}, other: ${other._values.length}');
    return Chroma(
        List.generate(_values.length, (i) => _values[i] + other._values[i]));
  }

  Chroma operator /(num denominator) {
    return Chroma(_values.map((e) => e / denominator).toList());
  }

  Chroma operator *(num factor) {
    return Chroma(_values.map((e) => e * factor).toList());
  }

  double operator [](int index) => _values[index];

  @override
  Iterator<double> get iterator => _values.iterator;

  @override
  String toString() {
    return _values.map((e) => e.toStringAsFixed(3)).join(', ');
  }

  @override
  bool operator ==(Object other) {
    if (other is Chroma) {
      return listEquals(_values, other._values);
    }

    return false;
  }

  @override
  int get hashCode => _values.fold(0, (value, e) => value ^ e.hashCode);
}

///必ず12個の特徴量をもったクロマ
@immutable
class PCP extends Chroma {
  PCP(super.values) : assert(values.length == 12);

  factory PCP.fromNotes(Notes notes) {
    final values = List.filled(12, 0.0);

    final indexes = notes.map((e) => Note.C.degreeTo(e));
    for (final i in indexes) {
      values[i] = 1;
    }

    return PCP(values);
  }

  static final zero = PCP(List.filled(12, 0));
}

@immutable
class ChromaContext {
  const ChromaContext({
    required this.lowest,
    required this.perOctave,
  });

  static const guitar = ChromaContext(
    lowest: MusicalScale.E2,
    perOctave: 6,
  );

  static const big = ChromaContext(
    lowest: MusicalScale.C1,
    perOctave: 7,
  );

  final MusicalScale lowest;
  final int perOctave;

  MusicalScale get highest => lowest.transpose(12 * perOctave - 1);

  @override
  String toString() => '$lowest-$highest';

  Bin toEqualTemperamentBin() => equalTemperamentBin(lowest, highest);

  List<double> toHzList() => MusicalScale.hzList(lowest, highest);
}
