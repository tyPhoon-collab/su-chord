import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../utils/formula.dart';
import 'chord.dart';
import 'chroma.dart';
import 'equal_temperament.dart';

abstract interface class ChromaListFilter {
  List<Chroma> call(List<Chroma> chroma);
}

class ThresholdFilter implements ChromaListFilter {
  const ThresholdFilter({required this.threshold});

  final double threshold;

  @override
  List<Chroma> call(List<Chroma> chroma) =>
      chroma.where((e) => e.max >= threshold).toList();
}

class AverageFilter implements ChromaListFilter {
  const AverageFilter({required this.kernelRadius}) : assert(kernelRadius > 0);

  final int kernelRadius;

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
          (i) =>
              normalDistribution((i - kernelRadius).toDouble(), 0, stdDevIndex),
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

class IntervalChordChangeDetector implements ChromaListFilter {
  IntervalChordChangeDetector({required this.interval, required this.dt}) {
    _intervalSeconds = interval.inMicroseconds / 1000000;
    if (_intervalSeconds <= dt) {
      debugPrint('Interval is less than dt. This filter will be ignored');
    }
  }

  final double dt;
  final Duration interval;
  late final double _intervalSeconds;

  @override
  List<Chroma> call(List<Chroma> chromas) {
    if (chromas.isEmpty) return [];
    if (_intervalSeconds <= dt) return chromas;

    final slices = <int>[];
    double accumulatedTime = 0;
    int accumulatedCount = 0;

    for (int i = 0; i < chromas.length; i++) {
      accumulatedTime += dt;
      accumulatedCount++;

      if (accumulatedTime >= _intervalSeconds) {
        slices.add(accumulatedCount);
        accumulatedTime -= _intervalSeconds;
        accumulatedCount = 0;
      }
    }

    //コンピュータ特有の誤差を考慮
    if (accumulatedTime + epsilon >= _intervalSeconds) {
      slices.add(accumulatedCount);
    }

    return _average(chromas, slices);
  }
}

///少ないコードタイプで推定することで、コード区間を概算する
class TriadChordChangeDetector implements ChromaListFilter {
  // TriadChordChangeDetector({this.lookaheadSize = 5});

  final _templates = [
    for (final root in Note.values)
      for (final type in ChordType.triads)
        Chord.fromType(type: type, root: root)
  ];

  // final int lookaheadSize;

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return [];

    final chords = chroma
        .map((e) => maxBy(_templates, (t) => e.cosineSimilarity(t.pcp))!)
        .toList();

    Chord preChord = chords.first;
    int count = 1;
    final slices = <int>[];

    for (final chord in chords.skip(1)) {
      if (chord != preChord) {
        slices.add(count);
        count = 0;
      }
      preChord = chord;
      count++;
    }

    slices.add(count);

    return _average(chroma, slices);
  }
}

class DifferenceByThresholdChordChangeDetector implements ChromaListFilter {
  const DifferenceByThresholdChordChangeDetector({required this.threshold});

  final double threshold;

  @override
  List<Chroma> call(List<Chroma> chroma) {
    // TODO: implement filter
    throw UnimplementedError();
  }
}

class CosineSimilarityChordChangeDetector implements ChromaListFilter {
  const CosineSimilarityChordChangeDetector({required this.threshold})
      : assert(0 <= threshold && threshold <= 1, 'threshold MUST BE [0, 1]');

  final double threshold;

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return const [];

    final slices = <int>[];

    Chroma preChroma = chroma.first;
    int count = 1;
    for (final value in chroma.skip(1)) {
      final score = value.cosineSimilarity(preChroma);
      if (score < threshold) {
        slices.add(count);
        count = 0;
      }
      preChroma = value;
      count++;
    }

    slices.add(count);

    return _average(chroma, slices);
  }
}

///source [1,2,3,4,5], slices [3,2]
///-> [2, 4.5]
///
///source [1,2,3,4,5,6], slices [3,2]
///-> [2, 4.5]
List<Chroma> _average(List<Chroma> source, List<int> slices) {
  assert(slices.sum <= source.length);

  final averages = <Chroma>[];

  int startIndex = 0;
  for (final sliceSize in slices) {
    final slice = source.sublist(startIndex, startIndex + sliceSize);
    final sum = slice.reduce((a, b) => a + b);
    averages.add(sum / sliceSize);
    startIndex += sliceSize;
  }

  return averages;
}
