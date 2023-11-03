import 'dart:math';

import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../data_set.dart';
import '../util.dart';

Future<void> main() async {
  final f = factory8192_0;
  late final ChordProgression corrects;

  setUpAll(() async {
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

    test('estimator', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter(),
        filters: f.filter.eval,
      );
      final progress = estimator.estimate(await DataSet().sample);
      expect(progress.length, 20);
    });
  });

  test('threshold', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.reassignCombFilter(),
      filters: [
        const PowerThresholdChordChangeDetector(threshold: 15),
      ],
    );
    final progress = estimator.estimate(await DataSet().sample);
    expect(progress.length, 20);
  });

  test('triad', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.reassignCombFilter(),
      filters: [
        const ThresholdFilter(threshold: 100),
        TriadChordChangeDetector(),
      ],
    );
    final progress = estimator.estimate(await DataSet().sample);
    expect(progress.length, 20);
  });

  group('fold', () {
    final base = [
      const ThresholdFilter(threshold: 20),
      // IntervalChordChangeDetector(interval: 0.5.seconds, dt: f.context.dt),
    ];

    test('no smoothing', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter(),
        filters: base,
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });

    test('average', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter(),
        filters: [
          ...base,
          const AverageFilter(kernelRadius: 1),
        ],
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });

    test('gaussian', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter(),
        filters: [
          ...base,
          GaussianFilter.dt(stdDev: 0.5, dt: f.context.dt),
        ],
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });
  });

  group('pre frame', () {

    group('cosine similarity', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosineSimilarity( 0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosineSimilarity(0.9),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('log', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable:
          f.guitarRange.reassignCombFilter(scalar: MagnitudeScalar.ln),
          filters: [
            ThresholdFilter(threshold: log(15)),
            const PreFrameCheckChordChangeDetector.cosineSimilarity(0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });

    group('tonal centroid', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.tonalCentroid( 0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.tonalCentroid(0.9),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });
  });

}
