import 'dart:math';

import 'package:flutter/cupertino.dart';

import '../../utils/formula.dart';
import '../chroma.dart';

abstract interface class ChromaListFilter {
  List<Chroma> call(List<Chroma> chroma);
}

@visibleForTesting
class ThresholdFilter implements ChromaListFilter {
  const ThresholdFilter(this.threshold);

  final double threshold;

  @override
  String toString() => 'threshold $threshold';

  @override
  List<Chroma> call(List<Chroma> chroma) =>
      chroma.where((e) => e.l2norm >= threshold).toList();
}

class AverageFilter implements ChromaListFilter {
  const AverageFilter({required this.kernelRadius}) : assert(kernelRadius > 0);

  final int kernelRadius;

  @override
  String toString() => 'average $kernelRadius';

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return const [];
    final filteredChroma = List.generate(chroma.length, (index) {
      Chroma sum = Chroma.zero(chroma.first.length);
      int count = 0;

      for (int i = -kernelRadius; i <= kernelRadius; i++) {
        final neighborIndex = index + i;
        if (neighborIndex < 0 || chroma.length <= neighborIndex) continue;

        sum += chroma[neighborIndex];
        count++;
      }

      return sum / count;
    });

    return filteredChroma;
  }
}

class GaussianFilter implements ChromaListFilter {
  GaussianFilter({
    required this.stdDevIndex,
    required this.kernelRadius,
  })  : assert(stdDevIndex > 0),
        assert(kernelRadius > 0),
        _kernel = List.generate(
          kernelRadius * 2 + 1,
          (i) => normalDistribution(
            (i - kernelRadius).toDouble(),
            0,
            stdDevIndex,
          ),
        );

  ///stdDevの単位を秒数とする
  ///時間分解能を渡すことで、秒数でのガウシアンフィルタを考慮する
  factory GaussianFilter.dt({
    required double stdDev,
    required double dt,
    double kernelRadiusStdDevMultiplier = 3,
  }) {
    return GaussianFilter(
      stdDevIndex: stdDev / dt,
      kernelRadius: stdDev * kernelRadiusStdDevMultiplier ~/ dt,
    );
  }

  @override
  String toString() => 'gaussian $kernelRadius';

  final double stdDevIndex;
  final int kernelRadius;
  late final List<double> _kernel;

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return const [];

    final filteredChroma = List.generate(chroma.length, (index) {
      Chroma sum = Chroma.zero(chroma.first.length);
      for (int i = -kernelRadius; i <= kernelRadius; i++) {
        final neighborIndex = index + i;
        if (neighborIndex < 0 || chroma.length <= neighborIndex) continue;

        sum += chroma[neighborIndex] * _kernel[i + kernelRadius];
      }
      return sum;
    });

    return filteredChroma;
  }
}

class CompressionFilter implements ChromaListFilter {
  const CompressionFilter();

  @override
  String toString() => 'compression';

  @override
  List<Chroma> call(List<Chroma> chroma) {
    return chroma.map(_compress).toList();
  }

  Chroma _compress(Chroma c) {
    final indexes = c.maxSortedIndexes;
    final index = indexes.skip(1).first;
    final compressValue = c.toList()[index];
    return Chroma(c.map((e) => min(compressValue, e)).toList());
  }
}
