// ignore_for_file: avoid_redundant_argument_values

import 'package:chord/domains/chord.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';
import 'comparator.dart';
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
    final f = factory4096_0;

    group('pattern matching', () {
      group('liner', () {
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
        });

        group('tonal', () {
          test('tonal centroid comb', () async {
            await Evaluator(
              estimator: PatternMatchingChordEstimator(
                chromaCalculable: f.guitar.reassignCombFilter(),
                scoreCalculator:
                    const ScoreCalculator.cosine(ToTonalCentroid()),
                chordChangeDetectable: f.hcdf.eval,
              ),
            )
                .evaluate(contexts, header: 'tonal')
                .toCSV('test/outputs/tonal_centroid.csv');
          });

          test('tonal interval space comb musical weight', () async {
            await Evaluator(
              estimator: PatternMatchingChordEstimator(
                chromaCalculable: f.guitar.reassignCombFilter(),
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalIntervalVector.musical(),
                ),
                chordChangeDetectable: f.hcdf.eval,
              ),
            )
                .evaluate(contexts, header: 'tiv musical')
                .toCSV('test/outputs/tiv_musical.csv');
          });

          test('tonal interval space comb symbolic weight', () async {
            await Evaluator(
              estimator: PatternMatchingChordEstimator(
                chromaCalculable: f.guitar.reassignCombFilter(),
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalIntervalVector.symbolic(),
                ),
                chordChangeDetectable: f.hcdf.eval,
              ),
            )
                .evaluate(contexts, header: 'tiv symbolic')
                .toCSV('test/outputs/tiv_symbolic.csv');
          });

          test('tonal interval space comb harte weight', () async {
            await Evaluator(
              estimator: PatternMatchingChordEstimator(
                chromaCalculable: f.guitar.reassignCombFilter(),
                scoreCalculator: const ScoreCalculator.cosine(
                  ToTonalIntervalVector.harte(),
                ),
                chordChangeDetectable: f.hcdf.eval,
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
                templateScalar: HarmonicsChromaScalar(until: 6),
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
                templateScalar: HarmonicsChromaScalar(until: 6),
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
                templateScalar: const OnlyThirdHarmonicChromaScalar(0.2),
              ),
            )
                .evaluate(contexts, header: 'third scaled')
                .toCSV('test/outputs/third_scalar.csv');
          });

          group('harmonics scaled', () {
            late final estimator = PatternMatchingChordEstimator(
              chromaCalculable:
                  f.guitar.reassignment(scalar: MagnitudeScalar.ln),
              chordChangeDetectable: f.hcdf.eval,
            );

            test('0.6 4', () async {
              await Evaluator(
                estimator: estimator.copyWith(
                  templateScalar: HarmonicsChromaScalar(),
                ),
              )
                  .evaluate(contexts, header: 'harmonics scaled')
                  .toCSV('test/outputs/harmonics_scalar_4.csv');
            });

            test('0.6 6', () async {
              await Evaluator(
                estimator: estimator.copyWith(
                  templateScalar: HarmonicsChromaScalar(until: 6),
                ),
              )
                  .evaluate(contexts, header: 'harmonics scaled')
                  .toCSV('test/outputs/harmonics_scalar_6.csv');
            });

            test('0.7 6', () async {
              await Evaluator(
                estimator: estimator.copyWith(
                  templateScalar: HarmonicsChromaScalar(factor: 0.7, until: 6),
                ),
              )
                  .evaluate(contexts, header: 'harmonics scaled')
                  .toCSV('test/outputs/harmonics_scalar_6_07.csv');
            });

            test('0.8 6', () async {
              await Evaluator(
                estimator: estimator.copyWith(
                  templateScalar: HarmonicsChromaScalar(factor: 0.8, until: 6),
                ),
              )
                  .evaluate(contexts, header: 'harmonics scaled')
                  .toCSV('test/outputs/harmonics_scalar_6_08.csv');
            });
          });
        });
      });
      group('mean', () {
        group('reassign', () {
          test('_', () async {
            await Evaluator(
              estimator: MeanTemplatePatternMatchingChordEstimator(
                chromaCalculable:
                    f.guitar.reassignment(scalar: MagnitudeScalar.ln),
                chordChangeDetectable: f.hcdf.eval,
                templateScalar: HarmonicsChromaScalar(until: 6),
              ),
            )
                .evaluate(contexts, header: 'mean reassign')
                .toCSV('test/outputs/mean_reassign.csv');
          });
        });
      });
    });

    group('spot compare', () {
      final f = factory4096_0;

      final compare = SpotComparator(
        chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
        writer: const PCPChartWriter(),
      );
      test('A 12 10', () async {
        await compare(
          source:
              'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav',
          index: 10,
          chords: [
            Chord.parse('Asus4'),
            Chord.parse('Dadd9'),
          ],
        );
      });

      test('D 11 1', () async {
        await compare(
          source: 'assets/evals/RealStrat/11_RealStrat_Elite.wav',
          index: 1,
          chords: [
            Chord.parse('C'),
            Chord.parse('Cadd9'),
          ],
        );
      });

      test('A 11 1', () async {
        await compare(
          source:
              'assets/evals/Halion_CleanGuitarVX/11_107_Halion_CleanGuitarVX.wav',
          index: 1,
          chords: [
            Chord.parse('C'),
            Chord.parse('Cadd9'),
          ],
        );
      });

      test('A 2 2', () async {
        await compare(
          source: 'assets/evals/Halion_CleanGuitarVX/2_東京-03.wav',
          index: 2,
          chords: [
            Chord.parse('F#m7b5'),
            Chord.parse('Am6'),
          ],
        );
      });
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
}
