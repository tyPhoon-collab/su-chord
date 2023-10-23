import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/reassignment.dart';
import 'package:chord/domains/estimator.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> main() async {
  final f = factory8192_0;
  late final AudioData data;
  late final ChordProgression corrects;

  void print(ChordProgression progression) {
    debugPrint('correct:\t\t$corrects');
    debugPrint('predict folded:\t${progression.simplify()}');
    debugPrint('predict:\t\t$progression');
  }

  setUpAll(() async {
    data = await AudioLoader.sample.load(sampleRate: f.context.sampleRate);
    corrects = ChordProgression.fromCSVRow(
        (await CSVLoader.corrects.load())[1]
        .skip(1)
        .map((e) => e.toString())
        .toList(),
    );
  });

  group('interval', () {
    test('just', () {
      final ccd = IntervalChordChangeDetector(interval: 2.seconds, dt: 1);
      final chromas = List.filled(4, Chroma.empty); // 4 sec
      expect(ccd(chromas).length, 2); // 4 sec / 2 sec -> 2
    });

    test('over', () {
      final ccd = IntervalChordChangeDetector(interval: 2.seconds, dt: 1.1);
      final chromas = List.filled(4, Chroma.empty); // 4.4 sec
      expect(ccd(chromas).length, 2); // 4.4 sec / 2 sec -> 2
    });

    test('less', () {
      final ccd = IntervalChordChangeDetector(interval: 2.seconds, dt: 0.9);
      final chromas = List.filled(4, Chroma.empty); // 3.6 sec
      expect(ccd(chromas).length, 1); // 3.6 sec / 2 sec -> 1
    });

    test('less than dt', () {
      final ccd = IntervalChordChangeDetector(interval: 0.1.seconds, dt: 1);
      final chromas = List.filled(4, Chroma.empty);
      expect(ccd(chromas).length, 4); // same as chromas.length
    });
  });

  test('triad', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: ReassignmentChromaCalculator(),
      filters: [
        const ThresholdFilter(threshold: 100),
        TriadChordChangeDetector(),
      ],
    );
    final progress = estimator.estimate(data);
    expect(progress.length, 20);
  });

  group('fold', () {
    final base = [
      const ThresholdFilter(threshold: 10),
      IntervalChordChangeDetector(interval: 0.5.seconds, dt: f.context.dt),
    ];


    test('no smoothing', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter,
        filters: base,
      );
      final progression = estimator.estimate(data);
      print(progression);
    });

    test('average', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter,
        filters: [
          ...base,
          const AverageFilter(kernelRadius: 1),
        ],
      );
      final progression = estimator.estimate(data);
      print(progression);
    });

    test('gaussian', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter,
        filters: [
          ...base,
          GaussianFilter.dt(stdDev: 0.5, dt: f.context.dt),
        ],
      );
      final progression = estimator.estimate(data);
      print(progression);
    });
  });

  test('cosine similarity', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.reassignCombFilter,
      filters: [
        const ThresholdFilter(threshold: 10),
        const CosineSimilarityChordChangeDetector(threshold: 0.75),
      ],
    );
    final progression = estimator.estimate(data);
    print(progression);
  });
}

