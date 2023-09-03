import 'package:chord/config.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  group('interval', () {
    test('just', () {
      final ccd = IntervalChordChangeDetector(interval: 1.seconds, dt: 0.25);
      final chromas = List.filled(8, Chroma.empty);
      expect(ccd.filter(chromas).length, 2);
    });

    test('over', () {
      final ccd = IntervalChordChangeDetector(interval: 1.seconds, dt: 0.251);
      final chromas = List.filled(8, Chroma.empty);
      expect(ccd.filter(chromas).length, 2);
    });

    test('less', () {
      final ccd = IntervalChordChangeDetector(interval: 1.seconds, dt: 0.251);
      final chromas = List.filled(11, Chroma.empty);
      expect(ccd.filter(chromas).length, 2);
    });
  });

  test('triad', () async {
    final data = await AudioLoader.sample.load(sampleRate: Config.sampleRate);
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: ReassignmentChromaCalculator(),
      filters: [
        ThresholdFilter(threshold: 100),
        TriadChordChangeDetector(),
      ],
    );
    final progress = estimator.estimate(data);
    expect(progress.length, 20);
  });
}
