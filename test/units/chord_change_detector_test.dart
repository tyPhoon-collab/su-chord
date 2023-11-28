// ignore_for_file: avoid_redundant_argument_values

import 'dart:math';

import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../data_set.dart';
import '../util.dart';
import '../writer.dart';

Future<void> main() async {
  final f = factory8192_0;
  late final ChordProgression corrects;

  setUpAll(() async {
    corrects = ChordProgression.fromChordRow(
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
      expect(
        ccd(chromas),
        [const Slice(0, 2), const Slice(2, 4)],
      ); // 4 sec / 2 sec -> 2
    });

    test('over', () {
      final ccd = IntervalChordChangeDetector(interval: 2.seconds, dt: 1.1);
      final chromas = List.filled(4, Chroma.empty); // 4.4 sec
      expect(
        ccd(chromas),
        [const Slice(0, 2), const Slice(2, 4)],
      ); // 4.4 sec / 2.2 sec -> 2
    });

    test('less', () {
      final ccd = IntervalChordChangeDetector(interval: 2.seconds, dt: 0.9);
      final chromas = List.filled(4, Chroma.empty); // 3.6 sec
      expect(
        ccd(chromas),
        [const Slice(0, 3)],
      ); // 3.6 sec / 2.7 sec -> 1
    });

    test('less than dt', () {
      final ccd = IntervalChordChangeDetector(interval: 0.1.seconds, dt: 1);
      final chromas = List.filled(4, Chroma.empty);
      expect(ccd(chromas), [
        const Slice(0, 1),
        const Slice(1, 2),
        const Slice(2, 3),
        const Slice(3, 4),
      ]); // same as chromas.length
    });

    test('estimator', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitar.reassignCombFilter(),
        chordChangeDetectable: f.hcdf.eval,
      );
      final progress = estimator.estimate(await DataSet().sample);
      debugPrint('deltaTime: ${f.context.dt}');
      debugPrint(progress.toDetailString());
      expect(progress.length, 20);
    });
  });

  group('threshold', () {
    test('toy', () {
      final chromas = [1, 10, 100, 5, 5, 5, 20, 0, 0, 0, 20, 20, 20, -1]
          .map((e) => Chroma([e.toDouble()]))
          .toList();
      final slices = const PowerThresholdChordChangeDetector(10).call(chromas);
      debugPrint(slices.toString());
      expect(slices[0], const Slice(1, 3));
      expect(slices[1], const Slice(6, 7));
      expect(slices[2], const Slice(10, 13));
    });

    test('estimate', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitar.reassignCombFilter(),
        chordChangeDetectable: f.hcdf.threshold(15),
      );
      final progress = estimator.estimate(await DataSet().sample);
      debugPrint(progress.toDetailString());
      expect(progress.length, 20);
    });
  });

  test('triad', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.reassignCombFilter(),
      chordChangeDetectable: f.hcdf.triad(threshold: 15),
    );
    final progress = estimator.estimate(await DataSet().sample);
    expect(progress.length, 20);
  });

  group('fold', () {
    test('no smoothing', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitar.reassignCombFilter(),
        chordChangeDetectable: f.hcdf.frame(20),
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });

    test('average', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitar.reassignCombFilter(),
        chordChangeDetectable: f.hcdf.frame(20),
        filters: [
          const AverageFilter(kernelRadius: 1),
        ],
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });

    test('gaussian', () async {
      final estimator = PatternMatchingChordEstimator(
        chromaCalculable: f.guitar.reassignCombFilter(),
        chordChangeDetectable: f.hcdf.frame(20),
        filters: [
          GaussianFilter.dt(stdDev: 0.5, dt: f.context.dt),
        ],
      );
      final progression = estimator.estimate(await DataSet().sample);
      printProgressions(progression, corrects);
    });
  });

  group('pre frame', () {
    group('consequence', () {
      test('normal', () {
        final chromas = [
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
        ];

        const ccd = PreFrameCheckChordChangeDetector(
          scoreCalculator: ScoreCalculator.cosine(),
          threshold: 0.5,
        );
        final slices = ccd(chromas);
        logTest(slices);
        expect(slices, isNotEmpty);
        expect(slices.length, 1);
        expect(slices[0], const Slice(0, 4));
      });

      test('first not include', () {
        final chromas = [
          Chroma(const [0, 0, 0, 0]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
        ];

        const ccd = PreFrameCheckChordChangeDetector(
          scoreCalculator: ScoreCalculator.cosine(),
          threshold: 0.5,
        );
        final slices = ccd(chromas);
        logTest(slices);
        expect(slices.length, 1);
        expect(slices[0], const Slice(1, 5));
      });

      test('last not include', () {
        final chromas = [
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [1, 1, 1, 1]),
          Chroma(const [0, 0, 0, 0]),
        ];

        const ccd = PreFrameCheckChordChangeDetector(
          scoreCalculator: ScoreCalculator.cosine(),
          threshold: 0.5,
        );
        final slices = ccd(chromas);
        logTest(slices);
        expect(slices.length, 1);
        expect(slices[0], const Slice(0, 4));
      });
    });

    test('unstable', () {
      //不安定な部分は切り捨てる
      final chromas = [
        Chroma(const [0, 0, 0, 0]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [0, 0, 0, 0]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [0, 0, 0, 0]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [0, 0, 0, 0]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [1, 1, 1, 1]),
        Chroma(const [1, 1, 1, 1]),
      ];

      const ccd = PreFrameCheckChordChangeDetector(
        scoreCalculator: ScoreCalculator.cosine(),
        threshold: 0.5,
      );
      final slices = ccd(chromas);
      logTest(slices);
      expect(slices.length, 2);
      expect(slices[0], const Slice(1, 5));
      expect(slices[1], const Slice(10, 13));
    });

    group('cosine similarity', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 20,
            scoreThreshold: 0.8,
          ),
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 20,
            scoreThreshold: 0.9,
          ),
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('log', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable:
              f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: log(15),
            scoreThreshold: 0.8,
          ),
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });

    group('tonal centroid', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 20,
            scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
            scoreThreshold: 0.8,
          ),
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 20,
            scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
            scoreThreshold: 0.9,
          ),
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });
    });

    group('TIV', () {
      test('0.8', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 20,
            scoreCalculator:
                const ScoreCalculator.cosine(ToTonalIntervalVector.musical()),
            scoreThreshold: 0.8,
          ),
        );
        final progression = estimator.estimate(await DataSet().sample);
        printProgressions(progression, corrects);
      });

      test('0.9', () async {
        final estimator = PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 20,
            scoreCalculator:
                const ScoreCalculator.cosine(ToTonalIntervalVector.musical()),
            scoreThreshold: 0.9,
          ),
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
      chordChangeDetectable: f.hcdf.realtime(powerThreshold: 20),
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
