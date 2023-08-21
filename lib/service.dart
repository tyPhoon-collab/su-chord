import 'package:get/get.dart';

import 'config.dart';
import 'domains/chord_change_detector.dart';
import 'domains/chroma.dart';
import 'domains/estimate.dart';

void register() {
  //TODO サンプルレートなどの設定が変更された時に、再登録できるようにする
  const sampleRate = Config.sampleRate;
  // const chunkSize = Config.chunkSize;
  const chunkStride = Config.chunkStride;

  Get.lazyPut<ChromaCalculable>(() => ReassignmentChromaCalculator());
  Get.lazyPut<ChordChangeDetectable>(() => IntervalChordChangeDetector(
        interval: 2,
        dt: chunkStride / sampleRate,
      ));

  Get.lazyPut<ChordEstimable>(() => PatternMatchingChordEstimator(
        chromaCalculable: Get.find(),
        chordChangeDetectable: Get.find(),
      ));
}
