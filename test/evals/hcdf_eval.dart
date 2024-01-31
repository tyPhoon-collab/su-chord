// ignore_for_file: avoid_redundant_argument_values

import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/measure.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluator.dart';

Future<void> main() async {
  Measure.logger = null;
  HCDFEvaluator.progressionWriter = null;
  // HCDFEvaluator.correctionWriter = null;

  final contexts = [
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/Halion_CleanGuitarVX',
    //   const KonokiEADCDelegate(),
    // ),
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/Halion_CleanStratGuitar',
    //   const KonokiEADCDelegate(),
    // ),
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/HojoGuitar',
    //   const KonokiEADCDelegate(),
    // ),
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/RealStrat',
    //   const KonokiEADCDelegate(),
    // ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/Halion_CleanGuitarVX_nonsilent',
      const KonokiEADCDelegate(),
    ),
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/Halion_CleanStratGuitar_nonsilent',
    //   const KonokiEADCDelegate(),
    // ),
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/HojoGuitar_nonsilent',
    //   const KonokiEADCDelegate(),
    // ),
    // ...await EvaluationAudioDataContext.fromFolder(
    //   'assets/evals/RealStrat_nonsilent',
    //   const KonokiEADCDelegate(),
    // ),
  ];

  group('HCDF', () {
    final f = f_4096;
    final base = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      context: TemplateContext.harmonicScaling(until: 6),
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
                scoreThreshold: .8,
              ),
            ),
          'tonal' => base.copyWith(
              chordChangeDetectable: f.hcdf.preFrameCheck(
                powerThreshold: threshold,
                scoreCalculator:
                    const ScoreCalculator.cosine(ToTonalCentroid()),
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
      test('HCDF fold', () async {
        await HCDFEvaluator(estimator: estimable('frame'))
            .evaluate(contexts)
            .toCSV('test/outputs/HCDF/fold.csv');
      });

      test('HCDF threshold', () async {
        await HCDFEvaluator(estimator: estimable('threshold'))
            .evaluate(contexts)
            .toCSV('test/outputs/HCDF/threshold.csv');
      });

      test('HCDF cosine', () async {
        await HCDFEvaluator(estimator: estimable('cosine'))
            .evaluate(contexts)
            .toCSV('test/outputs/HCDF/pre_frame_cosine.csv');
      });

      test('HCDF tonal', () async {
        await HCDFEvaluator(estimator: estimable('tonal'))
            .evaluate(contexts)
            .toCSV('test/outputs/HCDF/pre_frame_tonal_cosine.csv');
      });

      test('HCDF tiv', () async {
        await HCDFEvaluator(estimator: estimable('tiv'))
            .evaluate(contexts)
            .toCSV('test/outputs/HCDF/pre_frame_tiv_cosine.csv');
      });
    });

    group('visualize', () {
      Table.bypass = false;
      const index = 0;

      test('v fold', () async {
        await HCDFVisualizer(estimator: estimable('frame')).visualize(
          contexts[index],
          title: 'frame',
        );
      });

      test('v threshold', () async {
        await HCDFVisualizer(estimator: estimable('threshold')).visualize(
          contexts[index],
          title: 'threshold',
        );
      });

      test('v cosine', () async {
        await HCDFVisualizer(estimator: estimable('cosine')).visualize(
          contexts[index],
          title: 'cosine',
        );
      });

      test('v tonal', () async {
        await HCDFVisualizer(estimator: estimable('tonal')).visualize(
          contexts[index],
          title: 'tonal',
        );
      });

      test('v tiv', () async {
        await HCDFVisualizer(estimator: estimable('tiv')).visualize(
          contexts[index],
          title: 'tiv',
        );
      });
    });
  });
}