import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/reassignment.dart';
import 'package:chord/domains/estimator.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

Future<void> main() async {
  final f = factory8192_0;
  final data = await AudioLoader.sample.load(sampleRate: f.context.sampleRate);

  group('interval', () {
    test('just', () {
      final ccd = IntervalChordChangeDetector(interval: 1.seconds, dt: 0.25);
      final chromas = List.filled(8, Chroma.empty);
      expect(ccd(chromas).length, 2);
    });

    test('over', () {
      final ccd = IntervalChordChangeDetector(interval: 1.seconds, dt: 0.251);
      final chromas = List.filled(8, Chroma.empty);
      expect(ccd(chromas).length, 2);
    });

    test('less', () {
      final ccd = IntervalChordChangeDetector(interval: 1.seconds, dt: 0.251);
      final chromas = List.filled(11, Chroma.empty);
      expect(ccd(chromas).length, 2);
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

  test('simple', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.reassignCombFilter,
      filters: [
        const ThresholdFilter(threshold: 10),
        IntervalChordChangeDetector(
          interval: 0.5.seconds,
          dt: f.context.dt,
        ),
      ],
    );
    final progress = estimator.estimate(data);
    expect(progress.length, 20);
  });

  test('cosine similarity', () async {
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.reassignCombFilter,
      filters: [
        const ThresholdFilter(threshold: 10),
        const CosineSimilarityChordChangeDetector(threshold: 0.8),
      ],
    );
    final progress = estimator.estimate(data);
    expect(progress.length, 20);
  });
}
