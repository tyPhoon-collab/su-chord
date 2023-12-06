import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';
import 'evaluator.dart';

Future<void> main() async {
  final contexts = await EvaluationAudioDataContext.fromFolder(
    'assets/evals/3371780/audio_mono-mic',
    const GuitarSetEADCDelegate(),
    filter: (path) => path.contains('comp'),
    // filter: (path) => path.contain('00_BN1-129-Eb_comp_mic.wav'),
    // filter: (path) => path.contains('01_Rock3-117-Bb_comp_mic.wav'),
    // filter: (path) => path.contains('05_BN1-129-Eb_comp_mic.wav'),
  );

  final f = factory4096_0;
  final base = PatternMatchingChordEstimator(
    chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    templateScalar: HarmonicsChromaScalar(until: 6),
  );

  const threshold = 30.0;

  ChordEstimable estimable(String name) => switch (name) {
        'frame' =>
          base.copyWith(chordChangeDetectable: f.hcdf.frame(threshold)),
        'threshold' =>
          base.copyWith(chordChangeDetectable: f.hcdf.threshold(threshold)),
        'cosine' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreThreshold: .9,
            ),
          ),
        'tonal' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
              scoreThreshold: .9,
            ),
          ),
        'tiv' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreCalculator: const ScoreCalculator.cosine(
                ToTonalIntervalVector.musical(),
              ),
              scoreThreshold: .9,
            ),
          ),
        _ => throw UnimplementedError(),
      };

  group('score', () {
    // Table.bypass = true;
    HCDFEvaluator.progressionWriter = null;

    test('HCDF fold', () async {
      await HCDFEvaluator(estimator: estimable('frame'))
          .evaluate(contexts, header: 'fold')
          .toCSV('test/outputs/HCDF/guitar_set_fold.csv');
    });

    test('HCDF threshold', () async {
      await HCDFEvaluator(estimator: estimable('threshold'))
          .evaluate(contexts, header: 'threshold')
          .toCSV('test/outputs/HCDF/guitar_set_threshold.csv');
    });

    test('HCDF cosine', () async {
      await HCDFEvaluator(estimator: estimable('cosine'))
          .evaluate(contexts, header: 'pre frame cosine')
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_cosine.csv');
    });

    test('HCDF tonal', () async {
      await HCDFEvaluator(estimator: estimable('tonal'))
          .evaluate(contexts, header: 'pre frame tonal cosine')
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_tonal_cosine.csv');
    });

    test('HCDF tiv', () async {
      await HCDFEvaluator(estimator: estimable('tiv'))
          .evaluate(contexts, header: 'pre frame TIV cosine')
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_tiv_cosine.csv');
    });
  });

  group('visualize', () {
    test('all', () async {
      for (final context in contexts) {
        await HCDFVisualizer(estimator: base).visualize(
          context,
          writerContext: LibROSASpecShowContext.of(f.context),
          title: context.fileName,
        );
      }
    });

    group('individual', () {
      const index = 0;

      test('v fold', () async {
        await HCDFVisualizer(estimator: estimable('frame')).visualize(
          contexts[index],
          title: 'guitar set frame',
        );
      });

      test('v threshold', () async {
        await HCDFVisualizer(estimator: estimable('threshold')).visualize(
          contexts[index],
          title: 'guitar set threshold',
        );
      });

      test('v cosine', () async {
        await HCDFVisualizer(estimator: estimable('cosine')).visualize(
          contexts[index],
          title: 'guitar set cosine',
        );
      });

      test('v tonal', () async {
        await HCDFVisualizer(estimator: estimable('tonal')).visualize(
          contexts[index],
          title: 'guitar set tonal',
        );
      });

      test('v tiv', () async {
        await HCDFVisualizer(estimator: estimable('tiv')).visualize(
          contexts[index],
          title: 'guitar set tiv',
        );
      });
    });
  });
}
