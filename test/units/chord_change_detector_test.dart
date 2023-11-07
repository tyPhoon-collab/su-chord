import 'dart:math';

import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:flutter/cupertino.dart';
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
        chromaCalculable: f.guitar.reassignCombFilter(),
        filters: f.filter.eval,
      );
      final progress = estimator.estimate(await DataSet().sample);
      expect(progress.length, 20);
    });
  });

  test('threshold', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.reassignCombFilter(),
      filters: [
        const PowerThresholdChordChangeDetector(threshold: 15),
      ],
    );
    final progress = estimator.estimate(await DataSet().sample);
    expect(progress.length, 20);
  });

  test('triad', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.reassignCombFilter(),
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
        chromaCalculable: f.guitar.reassignCombFilter(),
        filters: base,
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });

    test('average', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitar.reassignCombFilter(),
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
        chromaCalculable: f.guitar.reassignCombFilter(),
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
          chromaCalculable: f.guitar.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosine(0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosine(0.9),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('log', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable:
              f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
          filters: [
            ThresholdFilter(threshold: log(15)),
            const PreFrameCheckChordChangeDetector.cosine(0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });

    group('tonal centroid', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosineTonalCentroid(0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosineTonalCentroid(0.9),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });

    group('TIV', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosineMusicalTIV(0.8),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          filters: [
            const ThresholdFilter(threshold: 20),
            const PreFrameCheckChordChangeDetector.cosineMusicalTIV(0.9),
          ],
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });
  });

  test('stream', () async {
    final f = factory4096_0;
    const bufferChunkSize = 4096;
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      filters: f.filter.realtime(threshold: 20),
      templateScalar: HarmonicsChromaScalar(until: 6),
    );
    final data = await DataSet().sample;

    debugPrint('Stream emulating...');
    int count = 0;

    await for (final progression in const AudioStreamEmulator(
      bufferChunkSize: bufferChunkSize,
      sleepDuration: Duration(milliseconds: 100),
    ).stream(data).map((data) => estimator.estimate(data, false))) {
      count++;
      printSeparation();
      debugPrint('count: $count');
      debugPrint('seek : ${bufferChunkSize * count / f.context.sampleRate}');
      debugPrint(progression.toString());
    }
    printSeparation();
    debugPrint(estimator.flush().toString());
  });
}
