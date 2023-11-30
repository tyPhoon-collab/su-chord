import 'package:chord/domains/estimator/search.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluator.dart';

void main() {
  late final Iterable<EvaluationAudioDataContext> contexts;

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
  });

  test('conv', () async {
    final f = factory8192_0;
    final logExtractor = f.extractor.threshold(scalar: MagnitudeScalar.ln);

    await Evaluator(
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
}
