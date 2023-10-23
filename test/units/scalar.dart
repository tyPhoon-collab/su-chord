import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final f = factory8192_0;
  late final AudioData data;

  setUpAll(() async {
    data = await AudioLoader.sample.load(sampleRate: f.context.sampleRate);
  });

  test('scalar', () async {
    final e1 = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.combFilter,
      filters: f.filter.eval,
    );

    final e2 = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.combFilter,
      filters: f.filter.eval,
      scalar: const ThirdHarmonicChromaScalar(0.2),
    );

    final progression1 = e1.estimate(data);
    final progression2 = e2.estimate(data);

    debugPrint(progression1.toString());
    debugPrint(progression2.toString());
  });
}
