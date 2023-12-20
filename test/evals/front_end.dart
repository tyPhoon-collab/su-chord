import 'package:chord/service.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final estimators = ProviderContainer().read(estimatorsProvider);

  Table.bypass = true;
  Evaluator.progressionWriter = null;
  // _Evaluator.correctionWriter = null;

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
