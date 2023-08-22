import 'package:flutter/foundation.dart';

typedef Bin = List<double>;

@immutable
class Point {
  const Point({required this.x, required this.y, required this.weight});

  final double x;
  final double y;
  final double weight;
}

///重み付きヒストグラムを構築するためのクラス
///便宜上、時系列順に並ぶように、x軸が上位の次元になっている
///また、binの外側に該当するものは無視される
///
///ex)
///final obj = WeightedHistogram2D(...)
///obj.add(...)
///obj.value[0] -> y軸のデータ(周波数)が得られるように設計
class WeightedHistogram2d {
  WeightedHistogram2d({required this.binX, required this.binY})
      : assert(binX.isNotEmpty),
        assert(binY.isNotEmpty) {
    values = List.generate(
      binX.length - 1,
      (_) => List.filled(binY.length - 1, 0.0),
      growable: false,
    );
  }

  factory WeightedHistogram2d.from(
    Iterable<Point> points, {
    required Bin binX,
    required Bin binY,
  }) {
    final obj = WeightedHistogram2d(binX: binX, binY: binY);
    points.forEach(obj.add);
    return obj;
  }

  late final List<List<double>> values;
  final Bin binX;
  final Bin binY;

  void add(Point point) {
    final ix = _index(point.x, binX);
    final iy = _index(point.y, binY);

    if (ix == null || iy == null) return;

    values[ix][iy] += point.weight;
  }

  int? _index(double val, List<double> bin) {
    if (val < bin.first || bin.last <= val) return null;

    for (int i = 0; i < bin.length - 1; ++i) {
      if (bin[i] <= val && val < bin[i + 1]) {
        return i;
      }
    }

    throw UnimplementedError();
  }
}
