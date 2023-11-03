import 'dart:math';

import 'package:collection/collection.dart';

import 'chroma.dart';

abstract interface class DistanceMetrics {
  double call(Chroma chroma, Chroma other);
}

final class Euclidean implements DistanceMetrics {
  const Euclidean();

  @override
  String toString() => 'euclidean';

  @override
  double call(Chroma chroma, Chroma other) {
    assert(chroma.length == other.length);
    double sum = 0;
    for (int i = 0; i < chroma.length; ++i) {
      sum += sqrt(chroma[i] * chroma[i] - other[i] * other[i]);
    }
    return sum;
  }
}

final class CosineSimilarity implements DistanceMetrics {
  const CosineSimilarity();

  @override
  String toString() => 'cosine similarity';

  @override
  double call(Chroma chroma, Chroma other) {
    assert(chroma.length == other.length);
    double sum = 0;
    for (int i = 0; i < chroma.length; ++i) {
      sum += chroma.l2normalized[i] * other.l2normalized[i];
    }
    return sum;
  }
}

abstract interface class ChromaMappable {
  Chroma call(Chroma c);
}

///based; Detecting Harmonic Change In Musical Audio
final class ToTonalCentroid implements ChromaMappable {
  const ToTonalCentroid({
    this.r1 = 1,
    this.r2 = 1,
    this.r3 = .5,
  });

  final double r1;
  final double r2;
  final double r3;

  @override
  String toString() => 'tonal centroid';

  @override
  Chroma call(Chroma c) {
    assert(c.length == 12);

    Iterable<double> calcCentroid(double r, double phase) {
      return [
        c.reduceIndexed((i, v, e) => v + e * r * sin(i * phase)),
        c.reduceIndexed((i, v, e) => v + e * r * cos(i * phase)),
      ];
    }

    final List<double> centroids = [
      ...calcCentroid(r1, 7 * pi / 6),
      ...calcCentroid(r2, 3 * pi / 2),
      ...calcCentroid(r3, 2 * pi / 3),
    ];

    final scaledCentroid = centroids.map((e) => e / c.l1norm).toList();

    assert(scaledCentroid.length == 6);

    return Chroma(scaledCentroid);
  }
}

///スコアを統括的に管理するためのクラス
///距離の指標とクロマの変換器を渡す
final class ScoreCalculator {
  const ScoreCalculator(this.distanceMetrics, {this.mapper});

  const ScoreCalculator.cosine([this.mapper])
      : distanceMetrics = const CosineSimilarity();

  final DistanceMetrics distanceMetrics;
  final ChromaMappable? mapper;

  @override
  String toString() => '${mapper != null ? '$mapper ' : ''}$distanceMetrics';

  double call(Chroma chroma, Chroma other) =>
      distanceMetrics(_map(chroma), _map(other));

  Chroma _map(Chroma c) => mapper?.call(c) ?? c;
}
