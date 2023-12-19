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

mixin class _CalculateCentroid {
  Iterable<double> calcCentroid(Chroma c, double r, double phase) {
    return [
      c.reduceIndexed((i, v, e) => v + e * r * sin(i * phase)),
      c.reduceIndexed((i, v, e) => v + e * r * cos(i * phase)),
    ];
  }
}

///based; Detecting Harmonic Change In Musical Audio
final class ToTonalCentroid with _CalculateCentroid implements ChromaMappable {
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

    final List<double> centroids = [
      ...calcCentroid(c, r1, 7 * pi / 6),
      ...calcCentroid(c, r2, 3 * pi / 2),
      ...calcCentroid(c, r3, 2 * pi / 3),
    ];

    final scaledCentroid = centroids.map((e) => e / c.l1norm).toList();

    assert(scaledCentroid.length == 6);

    return Chroma(scaledCentroid);
  }
}

final class ToTonalIntervalVector
    with _CalculateCentroid
    implements ChromaMappable {
  const ToTonalIntervalVector({required this.weights})
      : assert(weights.length == 6);

  const ToTonalIntervalVector.musical()
      : weights = const [3, 8, 11.5, 15, 14.5, 7.5];

  const ToTonalIntervalVector.symbolic()
      : weights = const [2, 11, 17, 16, 19, 7];

  const ToTonalIntervalVector.harte() : weights = const [0, 0, 1, 0.5, 1, 0];

  final List<double> weights;

  @override
  String toString() => 'tonal interval vector';

  @override
  Chroma call(Chroma c) {
    assert(c.length == 12);

    final centroids = [
      for (int i = 0; i < 6; ++i)
        ...calcCentroid(c, weights[i], -(i + 1) * pi / 6)
    ];

    final scaledCentroid = centroids.map((e) => e / c.l1norm).toList();

    assert(scaledCentroid.length == 12);

    return Chroma(scaledCentroid);
  }
}

///スコアを統括的に管理するためのクラス
///距離の指標とクロマの変換器を渡す
final class ScoreCalculator {
  const ScoreCalculator(this.distanceMetrics, {this.mapper});

  const ScoreCalculator.cosine([this.mapper])
      : distanceMetrics = const CosineSimilarity();

  const ScoreCalculator.tivCosine()
      : distanceMetrics = const CosineSimilarity(),
        mapper = const ToTonalIntervalVector.musical();

  const ScoreCalculator.tonalCentroidCosine()
      : distanceMetrics = const CosineSimilarity(),
        mapper = const ToTonalCentroid();

  final DistanceMetrics distanceMetrics;
  final ChromaMappable? mapper;

  @override
  String toString() => '${mapper != null ? '$mapper ' : ''}$distanceMetrics';

  double call(Chroma a, Chroma b) => distanceMetrics(_map(a), _map(b));

  Chroma _map(Chroma c) => mapper?.call(c) ?? c;
}
