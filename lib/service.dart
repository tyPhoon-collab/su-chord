import 'package:get/get.dart';

import 'config.dart';
import 'domains/chroma.dart';
import 'domains/estimate.dart';
import 'domains/factory.dart';

void register() {
  //TODO サンプルレートなどの設定が変更された時に、再登録できるようにする
  final factory = EstimatorFactory(
    // const EstimatorFactoryContext(
    //   chunkSize: Config.chunkSize,
    //   chunkStride: Config.chunkStride,
    //   sampleRate: Config.sampleRate,
    // ),
    const EstimatorFactoryContext(
      chunkSize: 8192,
      chunkStride: 0,
      sampleRate: Config.sampleRate,
    ),
  );

  Get.lazyPut<ChromaCalculable>(
    // () => factory.guitarRange.reassignment,
    () => factory.guitarRange.combFilter,
  );

  Get.lazyPut<ChordEstimable>(
    // () => PatternMatchingChordEstimator(
    //   chromaCalculable: Get.find(),
    //   filters: factory.filter.eval,
    // ),

    () => PatternMatchingChordEstimator(
      chromaCalculable: Get.find(),
      filters: factory.filter.realtime,
    ),
  );
}
