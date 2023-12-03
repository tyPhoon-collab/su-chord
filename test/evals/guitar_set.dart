import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';
import 'evaluator.dart';

void main() {
  late final List<EvaluationAudioDataContext> contexts;

  setUpAll(() async {
    // CSV書き込みをするなら以下をコメント化
    Table.bypass = true;

    // コード推定結果を出力したいなら以下をコメント化
    Evaluator.progressionWriter = null;

    // コード推定の正解率を出力したいなら以下をコメント化
    // _Evaluator.correctionWriter = null;

    // 使用する音源はフォルダごとに管理されている
    contexts = [
      ...await EvaluationAudioDataContext.fromFolder(
        'assets/evals/3371780/audio_mono-mic',
        const GuitarSetEADCDelegate(),
        filter: (path) => path.contains('comp'),
        // filter: (path) =>
        //     path.contains('00_BN1-129-Eb_comp_mic.wav'), //デバッグ用、一曲のみロードする
      ),
    ];
  });

  final f = factory4096_0;
  final base = PatternMatchingChordEstimator(
    chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    templateScalar: HarmonicsChromaScalar(until: 6),
    chordChangeDetectable: f.hcdf.preFrameCheck(
      powerThreshold: 20,
      scoreThreshold: .9,
    ),
  );

  test('score', () async {
    await HCDFEvaluator(estimator: base)
        .evaluate(contexts)
        .toCSV('assets/test/outputs/guitar_set_cosine.csv');
  });

  test('visualize', () async {
    Table.bypass = false;

    logTest(contexts.length, title: 'CONTEXT LENGTH');

    for (final context in contexts) {
      await HCDFVisualizer(estimator: base).visualize(
        context,
        factoryContext: f.context,
        title: context.fileName,
      );
    }
  });
}
