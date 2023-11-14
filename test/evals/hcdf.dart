// ignore_for_file: avoid_redundant_argument_values

import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evalulator.dart';

void main() {
  late final Iterable<EvaluationAudioDataContext> contexts;

  setUpAll(() async {
    // CSV書き込みをするなら以下をコメント化
    // Table.bypass = true;

    // 計算時間を出力したいなら以下をコメント化
    Measure.logger = null;

    // コード推定結果を出力したいなら以下をコメント化
    // HCDFEvaluator.progressionWriter = null;

    // コード推定の正解率を出力したいなら以下をコメント化
    // HCDFEvaluator.correctionWriter = null;

    // 使用する音源はフォルダごとに管理されている
    contexts = [
      ...await EvaluationAudioDataContext.fromFolder(
          'assets/evals/Halion_CleanGuitarVX'),
      // ...await EvaluationAudioDataContext.fromFolder(
      //     'assets/evals/Halion_CleanStratGuitar'),
      // ...await EvaluationAudioDataContext.fromFolder('assets/evals/HojoGuitar'),
      // ...await EvaluationAudioDataContext.fromFolder('assets/evals/RealStrat'),
    ];
  });

  group('HCDF', () {
    final f = factory4096_0;

    test('HCDF fold', () {
      HCDFEvaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.frame(20),
        ),
      ).evaluate(contexts);
    });

    test('HCDF threshold', () {
      HCDFEvaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.threshold(15),
        ),
      ).evaluate(contexts);
    });

    test('HCDF cosine similarity', () {
      HCDFEvaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable:
              f.hcdf.preFrameCheck(threshold: 15, scoreThreshold: .9),
        ),
      ).evaluate(contexts);
    });

    test('HCDF tonal', () {
      HCDFEvaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 15,
            scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
            scoreThreshold: .8,
          ),
        ),
      ).evaluate(contexts);
    });

    test('HCDF TIV', () {
      HCDFEvaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignCombFilter(),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: 15,
            scoreCalculator: const ScoreCalculator.cosine(
              ToTonalIntervalVector.musical(),
            ),
            scoreThreshold: .8,
          ),
        ),
      ).evaluate(contexts);
    });
  });
}
