import 'package:chord/service.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'evaluator.dart';

void main() {
  late final Iterable<EvaluationAudioDataContext> contexts;
  final estimators = ProviderContainer().read(estimatorsProvider);

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

  test('all', () async {
    for (final MapEntry(:key, :value) in estimators.entries) {
      final estimator = await value();
      await Evaluator(
        estimator: estimator,
      )
          .evaluate(contexts, header: key)
          .toCSV('test/outputs/front_ends/$key.csv');
    }
  });

  test('one', () async {
    const id = 'main'; // change here

    final estimator = await estimators[id]!.call();
    await Evaluator(
      estimator: estimator,
    ).evaluate(contexts, header: id).toCSV('test/outputs/front_ends/$id.csv');
  });
}
