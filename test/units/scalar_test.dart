import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  final f = factory8192_0;

  test('scalar', () async {
    final data = await DataSet().sample;

    final e1 = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.combFilter(),
      filters: f.filter.eval,
    );

    final e2 = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.combFilter(),
      filters: f.filter.eval,
      templateScalar: const ThirdHarmonicChromaScalar(0.2),
    );

    final e3 = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.combFilter(),
      filters: f.filter.eval,
      templateScalar: HarmonicsChromaScalar(),
    );

    final progression1 = e1.estimate(data);
    final progression2 = e2.estimate(data);
    final progression3 = e3.estimate(data);

    debugPrint(progression1.toString());
    debugPrint(progression2.toString());
    debugPrint(progression3.toString());
  });
}
