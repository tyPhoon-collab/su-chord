import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/score.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../writer.dart';

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
    final f = f_4096;
    final chord = Chord.parse('C');

    final template =
        HarmonicsChromaScalar(until: 6).call(chord.unitPCP).l2normalized;

    final pcp = average(f.guitar
            .reassignment(scalar: MagnitudeScalar.ln)
            .call(await DataSet().C))
        .first;

    final score = const ScoreCalculator.cosine().call(pcp, template);

    logTest(score);
  });

  group('f-score', () {
    test('1 0 0', () {
      final f = FScore(1, 0, 0);
      logTest(f);
    });
    test('2 1 0', () {
      final f = FScore(2, 1, 0);
      logTest(f);
    });

    test('2 0 1', () {
      final f = FScore(2, 0, 1);
      logTest(f);
    });

    test('1 1 1', () {
      final f = FScore(1, 1, 1);
      logTest(f);
    });

    test('2 2 2', () {
      final f = FScore(2, 2, 2);
      logTest(f);
    });

    test('2 1 1', () {
      final f = FScore(2, 1, 1);
      logTest(f);
    });
  });
}
