import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../chord.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import '../score_calculator.dart';
import 'filter.dart';

///秒数によってコード区間を設定する
class IntervalChordChangeDetector implements ChromaListFilter {
  IntervalChordChangeDetector({required this.interval, required this.dt}) {
    _intervalSeconds = interval.inMicroseconds / 1000000;
    if (_intervalSeconds <= dt) {
      debugPrint('Interval is less than dt. This filter will be ignored');
    }
  }

  @override
  String toString() => 'interval HCDF $interval';

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

    return average(chromas, slices);
  }
}

///無音区間があれば、そこをコード区間の区切りとする
class PowerThresholdChordChangeDetector implements ChromaListFilter {
  const PowerThresholdChordChangeDetector({required this.threshold});

  final double threshold;

  @override
  String toString() => 'threshold HCDF $threshold';

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return [];

    final filteredChromas = Map.fromEntries(
        chroma.asMap().entries.where((e) => e.value.max >= threshold));

    final indexes = filteredChromas.keys;
    int count = 1;
    int preIndex = indexes.first;
    final slices = <int>[];

    for (final index in indexes.skip(1)) {
      if (index - 1 != preIndex) {
        slices.add(count);
        count = 0;
      }
      preIndex = index;
      count++;
    }

    slices.add(count);

    return average(filteredChromas.values.toList(), slices);
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
  String toString() => 'triad HCDF';

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return [];

    final chords = chroma
        .map((e) => maxBy(_templates, (t) => e.cosineSimilarity(t.unitPcp))!)
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

    return average(chroma, slices);
  }
}

class PreFrameCheckChordChangeDetector implements ChromaListFilter {
  const PreFrameCheckChordChangeDetector({
    required this.scoreCalculable,
    required this.threshold,
  });

  const PreFrameCheckChordChangeDetector.cosineSimilarity(this.threshold)
      : assert(0 <= threshold && threshold <= 1, 'threshold MUST BE [0, 1]'),
        scoreCalculable = const CosineSimilarityScore();

  const PreFrameCheckChordChangeDetector.tonalCentroid(this.threshold)
      : assert(0 <= threshold && threshold <= 1, 'threshold MUST BE [0, 1]'),
        scoreCalculable = const TonalCentroidScore();

  final double threshold;
  final ScoreCalculable scoreCalculable;

  @override
  String toString() => '$scoreCalculable HCDF $threshold';

  @override
  List<Chroma> call(List<Chroma> chroma) {
    if (chroma.isEmpty) return const [];

    final slices = <int>[];

    Chroma preChroma = chroma.first;
    int count = 1;
    for (final value in chroma.skip(1)) {
      final score = scoreCalculable(value, preChroma);
      debugPrint(score.toStringAsFixed(3));

      if (score < threshold) {
        slices.add(count);
        count = 0;
      }
      preChroma = value;
      count++;
    }

    slices.add(count);

    return average(chroma, slices);
  }
}
