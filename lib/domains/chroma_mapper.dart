import 'dart:math';

import 'package:collection/collection.dart';

import 'chroma.dart';

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

///３倍音のみ考慮する
class OnlyThirdHarmonicChromaScalar implements ChromaMappable {
  const OnlyThirdHarmonicChromaScalar(this.factor);

  final double factor;

  @override
  String toString() => 'third harmonic scalar-$factor';

  @override
  Chroma call(Chroma c) {
    return (c * factor).shift(7) + c;
  }
}

///Chord recognition by fitting rescaled chroma vectors to chord templates
///指数的に倍音をたたみ込む
///s^(i-1)に従う : i倍音
class HarmonicsChromaScalar implements ChromaMappable {
  HarmonicsChromaScalar({
    this.factor = 0.6,
    this.until = 4,
  })  : assert(
          0 < until && until <= 6,
          'only 0-6 harmonics can incorporate for pcp this class',
        ),
        _factors = List.generate(
          until,
          (index) => (
            harmonicIndex: _harmonics[index],
            factor: pow(factor, index).toDouble(),
          ),
        );

  final int until;
  final double factor;
  final Iterable<({int harmonicIndex, double factor})> _factors;

  ///https://xn--i6q789c.com/gakuten/baion.html
  ///基音
  ///1オクターブ
  ///1オクターブ+完全5度
  ///2オクターブ
  ///2オクターブ+長3度
  ///2オクターブ+完全5度
  static const _harmonics = [0, 0, 7, 0, 4, 7];

  @override
  String toString() => 'harmonic $factor-$until';

  @override
  Chroma call(Chroma c) {
    Chroma chroma = Chroma.zero(c.length);
    for (final v in _factors) {
      chroma += c.shift(v.harmonicIndex) * v.factor;
    }
    return chroma;
  }
}

class LogChromaScalar implements ChromaMappable {
  const LogChromaScalar();

  @override
  String toString() => 'log';

  @override
  Chroma call(Chroma c) => c.toLogScale();
}

class CombinedChromaScalar implements ChromaMappable {
  const CombinedChromaScalar(this.mappers);

  final Iterable<ChromaMappable> mappers;

  @override
  String toString() => mappers.join(', ');

  @override
  Chroma call(Chroma c) => mappers.fold(c, (chroma, mapper) => mapper(chroma));
}
