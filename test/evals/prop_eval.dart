// ignore_for_file: avoid_redundant_argument_values

import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/service.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluator.dart';

Future<void> main() async {
  final contexts = [
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/Halion_CleanGuitarVX',
      const KonokiEADCDelegate(),
    ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/Halion_CleanStratGuitar',
      const KonokiEADCDelegate(),
    ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/HojoGuitar',
      const KonokiEADCDelegate(),
    ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/RealStrat',
      const KonokiEADCDelegate(),
    ),
  ];

  // Table.bypass = true;
  Measure.logger = null;
  Evaluator.progressionWriter = null;

  group('prop', () {
    final f = f_4096;

    group('pattern matching', () {
      group('reassign comb', () {
        test('normal', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
            ),
          )
              .evaluate(contexts, header: 'reassign comb')
              .toCSV('test/outputs/reassign_comb.csv');
        });

        test('ln', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable:
                  f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
              chordChangeDetectable: f.hcdf.eval,
            ),
          )
              .evaluate(contexts, header: 'ln reassign comb')
              .toCSV('test/outputs/ln_reassign_comb.csv');
        });

        test('pcp scalar', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
              filters: [
                const CompressionFilter(),
              ],
            ),
          )
              .evaluate(contexts, header: 'compression')
              .toCSV('test/outputs/pcp_compression.csv');
        });
      });

      group('tonal', () {
        test('tonal centroid comb', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext(
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalCentroid(),
                ),
              ),
            ),
          )
              .evaluate(contexts, header: 'tonal')
              .toCSV('test/outputs/tonal_centroid.csv');
        });

        test('tonal interval space comb musical weight', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext(
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalIntervalVector.musical(),
                ),
              ),
            ),
          )
              .evaluate(contexts, header: 'tiv musical')
              .toCSV('test/outputs/tiv_musical.csv');
        });

        test('tonal interval space comb symbolic weight', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext(
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalIntervalVector.symbolic(),
                ),
              ),
            ),
          )
              .evaluate(contexts, header: 'tiv symbolic')
              .toCSV('test/outputs/tiv_symbolic.csv');
        });

        test('tonal interval space comb harte weight', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext(
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalIntervalVector.harte(),
                ),
              ),
            ),
          )
              .evaluate(contexts, header: 'tiv harte')
              .toCSV('test/outputs/tiv_harte.csv');
        });
      });

      group('reassign', () {
        test('ln template scale', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable:
                  f.guitar.reassignment(scalar: MagnitudeScalar.ln),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext.harmonicScaling(
                until: 6,
                detectableChords: DetectableChords.conv,
              ),
            ),
          )
              .evaluate(contexts, header: 'reassign')
              .toCSV('test/outputs/reassign.csv');
        });

        test('non reassign', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignment(
                // scalar: MagnitudeScalar.ln,
                isReassignFrequency: false,
                isReassignTime: false,
              ),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext.harmonicScaling(until: 6),
            ),
          )
              .evaluate(contexts, header: 'non reassign')
              .toCSV('test/outputs/non_reassign.csv');
        });
      });

      group('template scalar', () {
        test('third scaled', () async {
          await Evaluator(
            estimator: PatternMatchingChordEstimator(
              chromaCalculable: f.guitar.reassignCombFilter(),
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext(
                scalar: const OnlyThirdHarmonicChromaScalar(0.2),
              ),
            ),
          )
              .evaluate(contexts, header: 'third scaled')
              .toCSV('test/outputs/third_scalar.csv');
        });

        group('harmonics scaled', () {
          late final estimator = PatternMatchingChordEstimator(
            chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
            chordChangeDetectable: f.hcdf.eval,
          );

          test('0.6 4', () async {
            await Evaluator(
              estimator: estimator.copyWith(
                context: TemplateContext.harmonicScaling(),
              ),
            )
                .evaluate(contexts, header: 'harmonics scaled')
                .toCSV('test/outputs/harmonics_scalar_4.csv');
          });

          test('0.6 6', () async {
            await Evaluator(
              estimator: estimator.copyWith(
                context: TemplateContext.harmonicScaling(until: 6),
              ),
            )
                .evaluate(contexts, header: 'harmonics scaled')
                .toCSV('test/outputs/harmonics_scalar_6.csv');
          });

          test('0.7 6', () async {
            await Evaluator(
              estimator: estimator.copyWith(
                context: TemplateContext.harmonicScaling(factor: 0.7, until: 6),
              ),
            )
                .evaluate(contexts, header: 'harmonics scaled')
                .toCSV('test/outputs/harmonics_scalar_6_07.csv');
          });

          test('0.8 6', () async {
            await Evaluator(
              estimator: estimator.copyWith(
                context: TemplateContext.harmonicScaling(factor: 0.8, until: 6),
              ),
            )
                .evaluate(contexts, header: 'harmonics scaled')
                .toCSV('test/outputs/harmonics_scalar_6_08.csv');
          });
        });
      });
    });

    group('mean pattern matching', () {
      group('reassign', () {
        test('m normal', () async {
          await Evaluator(
            estimator: MeanTemplatePatternMatchingChordEstimator(
              chromaCalculable:
                  f.guitar.reassignment(scalar: MagnitudeScalar.ln),
              chordChangeDetectable: f.hcdf.eval,
              chordSelectable: f.selector.flatFive,
              context: MeanTemplateContext.harmonicScaling(
                until: 6,
                detectableChords: DetectableChords.conv,
              ),
            ),
          )
              .evaluate(contexts, header: 'mean reassign')
              .toCSV('test/outputs/mean_reassign.csv');
        });

        test('m ln', () async {
          await Evaluator(
            estimator: MeanTemplatePatternMatchingChordEstimator(
              chromaCalculable:
                  f.guitar.reassignment(scalar: MagnitudeScalar.ln),
              chordChangeDetectable: f.hcdf.eval,
              chordSelectable: f.selector.flatFive,
              context: MeanTemplateContext.harmonicScaling(
                until: 6,
                detectableChords: DetectableChords.conv,
                meanScalar: const LogChromaScalar(),
                sortedScoreTakeCount: 3,
                scoreThreshold: 0.8,
              ),
            ),
          )
              .evaluate(contexts, header: 'mean reassign ln')
              .toCSV('test/outputs/mean_reassign_ln.csv');
        });
      });
    });
  });
}
