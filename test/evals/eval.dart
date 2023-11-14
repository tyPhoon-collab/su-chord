// ignore_for_file: avoid_redundant_argument_values

import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/estimator/search.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/service.dart';
import 'package:chord/utils/measure.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluator.dart';

Future<void> main() async {
  late final Iterable<EvaluationAudioDataContext> contexts;

  setUpAll(() async {
    // CSV書き込みをするなら以下をコメント化
    Table.bypass = true;

    // 計算時間を出力したいなら以下をコメント化
    Measure.logger = null;

    // コード推定結果を出力したいなら以下をコメント化
    Evaluator.progressionWriter = null;

    // コード推定の正解率を出力したいなら以下をコメント化
    // _Evaluator.correctionWriter = null;

    // 使用する音源はフォルダごとに管理されている
    contexts = [
      ...await EvaluationAudioDataContext.fromFolder(
          'assets/evals/Halion_CleanGuitarVX'),
      ...await EvaluationAudioDataContext.fromFolder(
          'assets/evals/Halion_CleanStratGuitar'),
      ...await EvaluationAudioDataContext.fromFolder('assets/evals/HojoGuitar'),
      ...await EvaluationAudioDataContext.fromFolder('assets/evals/RealStrat'),
    ];
  });

  test('conv', () async {
    final f = factory8192_0;
    final logExtractor = f.extractor.threshold(scalar: MagnitudeScalar.ln);

    Evaluator(
      estimator: SearchTreeChordEstimator(
        chromaCalculable: f.guitar.stftCombFilter(scalar: MagnitudeScalar.ln),
        chordChangeDetectable: f.hcdf.eval,
        noteExtractable: logExtractor,
        chordSelectable: await f.selector.db,
      ),
    )
        .evaluate(
          contexts,
          header: 'search + log comb, $logExtractor, ${f.context}',
        )
        .toCSV('test/outputs/search_tree_comb_log.csv');
  });

  group('prop', () {
    final f = factory4096_0;

    test('reassign comb', () async {
      Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.eval,
        ),
      )
          .evaluate(contexts, header: 'reassign comb')
          .toCSV('test/outputs/main.csv');
    });

    group('tonal', () {
      test('tonal centroid comb', () async {
        Evaluator(
          estimator: PatternMatchingChordEstimator(
            chromaCalculable: f.guitar.reassignCombFilter(),
            scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
            chordChangeDetectable: f.hcdf.eval,
          ),
        )
            .evaluate(contexts, header: 'tonal')
            .toCSV('test/outputs/tonal_centroid.csv');
      });

      test('tonal interval space comb musical weight', () async {
        Evaluator(
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
        Evaluator(
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
        Evaluator(
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

    test('ln reassign comb', () async {
      Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable:
              f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
          chordChangeDetectable: f.hcdf.eval,
        ),
      )
          .evaluate(contexts, header: 'ln reassign comb')
          .toCSV('test/outputs/main.csv');
    });

    test('reassignment', () async {
      Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
          chordChangeDetectable: f.hcdf.eval,
          templateScalar: HarmonicsChromaScalar(until: 6),
        ),
      )
          .evaluate(contexts, header: 'reassignment')
          .toCSV('test/outputs/main.csv');
    });

    group('template scalar', () {
      test('third scaled', () {
        Evaluator(
          estimator: PatternMatchingChordEstimator(
            chromaCalculable: f.guitar.reassignCombFilter(),
            chordChangeDetectable: f.hcdf.eval,
            templateScalar: const ThirdHarmonicChromaScalar(0.2),
          ),
        )
            .evaluate(contexts, header: 'third scaled')
            .toCSV('test/outputs/third_scalar.csv');
      });

      test('harmonics scaled', () {
        Evaluator(
          estimator: PatternMatchingChordEstimator(
            chromaCalculable:
                f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
            chordChangeDetectable: f.hcdf.eval,
            templateScalar: HarmonicsChromaScalar(),
          ),
        )
            .evaluate(contexts, header: 'harmonics scaled')
            .toCSV('test/outputs/harmonics_scalar.csv');
      });
    });

    test('pcp scalar', () {
      Evaluator(
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

  //service.dartに登録されている推定器のテスト
  group('riverpods front end estimators', () {
    final estimators = ProviderContainer().read(estimatorsProvider);

    test('all', () async {
      for (final MapEntry(:key, :value) in estimators.entries) {
        final estimator = await value();
        Evaluator(
          estimator: estimator,
        )
            .evaluate(contexts, header: key)
            .toCSV('test/outputs/front_ends/$key.csv');
      }
    });

    test('one', () async {
      const id = 'main'; // change here

      final estimator = await estimators[id]!.call();
      Evaluator(
        estimator: estimator,
      ).evaluate(contexts, header: id).toCSV('test/outputs/front_ends/$id.csv');
    });
  });
}
