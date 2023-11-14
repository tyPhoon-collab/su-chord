// ignore_for_file: avoid_redundant_argument_values

import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluator.dart';

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
    final base = PatternMatchingChordEstimator(
      chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      templateScalar: HarmonicsChromaScalar(until: 6),
      filters: [
        const ThresholdFilter(31), //Deal as consecutive
        GaussianFilter.dt(stdDev: 0.5, dt: f.context.dt),
      ],
    );
    const threshold = 30.0;

    test('HCDF fold', () {
      HCDFEvaluator(
        estimator:
            base.copyWith(chordChangeDetectable: f.hcdf.frame(threshold)),
      ).evaluate(contexts);
    });

    test('HCDF threshold', () {
      HCDFEvaluator(
        estimator:
            base.copyWith(chordChangeDetectable: f.hcdf.threshold(threshold)),
      ).evaluate(contexts);
    });

    test('HCDF cosine similarity', () {
      HCDFEvaluator(
        estimator: base.copyWith(
          chordChangeDetectable:
              f.hcdf.preFrameCheck(threshold: threshold, scoreThreshold: .9),
        ),
      ).evaluate(contexts);
    });

    test('HCDF tonal', () {
      HCDFEvaluator(
        estimator: base.copyWith(
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: threshold,
            scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
            scoreThreshold: .8,
          ),
        ),
      ).evaluate(contexts);
    });

    test('HCDF TIV', () {
      HCDFEvaluator(
        estimator: base.copyWith(
          chordChangeDetectable: f.hcdf.preFrameCheck(
            threshold: threshold,
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
