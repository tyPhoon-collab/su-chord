import 'package:flutter/foundation.dart';

enum OverlapStatus {
  overlapping,
  anotherIsLate,
  anotherIsFast;

  bool get isOverlapping => this == OverlapStatus.overlapping;
}

@immutable
class SequenceAnnotation<T extends num> {
  const SequenceAnnotation(this.start, this.end);

  final T start;
  final T end;

  @override
  String toString() => '$start-$end';

  @override
  int get hashCode => start.hashCode ^ end.hashCode;

  @override
  bool operator ==(Object other) {
    return other is SequenceAnnotation &&
        start == other.start &&
        end == other.end;
  }

  OverlapStatus overlapStatus(Time other) {
    if (other.end <= start) return OverlapStatus.anotherIsFast;
    if (end <= other.start) return OverlapStatus.anotherIsLate;
    return OverlapStatus.overlapping;
  }
}

@immutable
final class Time extends SequenceAnnotation<double> {
  const Time(super.start, super.end) : assert(start <= end);

  factory Time.infinity(double start) => Time(start, double.infinity);

  factory Time.negativeInfinity(double end) =>
      Time(double.negativeInfinity, end);

  static Time zero = const Time(0, 0);

  double get duration => end - start;

  Slice toSlice(double deltaTime) =>
      Slice(start ~/ deltaTime, end ~/ deltaTime);

  Time copyWith({double? start, double? end}) =>
      Time(start ?? this.start, end ?? this.end);
}

@immutable
final class Slice extends SequenceAnnotation<int> {
  const Slice(super.start, super.end);

  int get size => end - start;

  Time toTime(double deltaTime) => Time(start * deltaTime, end * deltaTime);

  Slice operator +(int value) => Slice(start + value, end + value);
}
