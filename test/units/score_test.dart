import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/score.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../evals/comparator.dart';
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
    final f = factory4096_0;
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

  test('compare score', () async {
    final f = factory4096_0;

    final chords = [
      Chord.parse('Asus4'),
      Chord.parse('Dadd9'),
    ];

    final data = await const SimpleAudioLoader(
            path:
                'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav')
        .load(sampleRate: 22050);

    final pcp = average(f.guitar
            .reassignment(scalar: MagnitudeScalar.ln)
            .call(data.cutEvaluationAudioByIndex(10)))
        .first;

    for (final chord in chords) {
      final template =
          HarmonicsChromaScalar(until: 6).call(chord.unitPCP).l2normalized;

      final score = const ScoreCalculator.cosine().call(pcp, template);

      logTest('$chord: $score');
    }
  });

  group('compare mean template score', () {
    final f = factory4096_0;
    final comparator = MeanScoreSpotComparator(
      chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      scalar: HarmonicsChromaScalar(until: 6),
    );

    test('F#m7b5', () async {
      await comparator(
        source: 'assets/evals/Halion_CleanGuitarVX/2_東京-03.wav',
        index: 2,
      );
    });

    test('Am7b5', () async {
      await comparator(
        source: 'assets/evals/Halion_CleanGuitarVX/5_涙の天使に.wav',
        index: 4,
      );
    });

    test('Dadd9', () async {
      await comparator(
        source:
            'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav',
        index: 10,
      );
    });
  });

  test('compare chroma calc', () async {
    final f = factory4096_0;
    final chord = Chord.parse('C');

    final template =
        HarmonicsChromaScalar(until: 6).call(chord.unitPCP).l2normalized;

    final cc = [
      f.guitar.reassignment(),
      f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      f.guitar.reassignCombFilter(),
      f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln)
    ];

    for (final value in cc) {
      final pcp = average(value(await DataSet().C)).first;
      final score = const ScoreCalculator.cosine().call(pcp, template);

      logTest(score, title: value.toString());
    }
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
