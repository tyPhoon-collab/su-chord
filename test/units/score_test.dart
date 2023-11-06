import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../data_set.dart';

void main() {
  group('mapper', () {
    test('tonal centroid', () {
      final pcp = PCP(const [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0]);
      final tc = const ToTonalCentroid().call(pcp);
      debugPrint(tc.toString());
    });
  });

  group('metrics', () {
    test('cosine similarity', () async {
      final c1 = Chroma(const [1, 1, 1, 1]);
      expect(const CosineSimilarity().call(c1, c1), 1);

      final c2 = Chroma(const [-1, -1, -1, -1]);
      expect(const CosineSimilarity().call(c1, c2), -1);
    });
  });

  test('score', () async {
    final f = factory4096_0;
    final chord = Chord.parse('C');

    final template =
        HarmonicsChromaScalar(until: 6).call(chord.unitPCP).l2normalized;

    final chromas = f.guitar
        .reassignment(scalar: MagnitudeScalar.ln)
        .call(await DataSet().C);

    final pcp = f.filter.interval(4.seconds).call(chromas).first;

    final score = const ScoreCalculator.cosine().call(pcp, template);

    debugPrint(score.toString());
  });
}
