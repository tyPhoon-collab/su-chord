import 'dart:math';

import 'chroma.dart';
import 'chroma_mapper.dart';

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
