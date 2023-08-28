import 'package:get/get.dart';

import 'config.dart';
import 'domains/chroma.dart';
import 'domains/estimate.dart';
import 'domains/factory.dart';

void register() {
  //TODO サンプルレートなどの設定が変更された時に、再登録できるようにする
  final factory = EstimatorFactory(const FactoryContext(
    chunkSize: Config.chunkSize,
    chunkStride: Config.chunkStride,
    sampleRate: Config.sampleRate,
  ));

  Get.lazyPut<ChromaCalculable>(
    () => factory.guitarRange.reassignment,
  );

  Get.lazyPut<ChordEstimable>(() => PatternMatchingChordEstimator(
        chromaCalculable: Get.find(),
        filters: factory.filter.eval,
      ));
}
