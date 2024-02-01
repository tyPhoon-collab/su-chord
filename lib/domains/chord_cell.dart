import 'package:flutter/foundation.dart';

import '../utils/score.dart';
import 'annotation.dart';
import 'chord.dart';

export 'chord.dart';

@immutable
class ChordCell<T extends ChordBase<T>> implements Transposable<ChordCell<T>> {
  const ChordCell({
    this.chord,
    this.time,
  });

  const ChordCell.of(this.chord) : time = null;

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
