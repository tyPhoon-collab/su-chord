import 'package:get/get.dart';

import 'domains/chroma.dart';
import 'domains/estimate.dart';
import 'domains/filter.dart';

void register() {
  //TODO サンプルレートなどの設定が変更された時に、再登録できるようにする
  // const sampleRate = Config.sampleRate;
  // const chunkSize = Config.chunkSize;
  // const chunkStride = Config.chunkStride;

  Get.lazyPut<ChromaCalculable>(
    () => ReassignmentChromaCalculator(),
    // () => CombFilterChromaCalculator(
    //     chunkSize: 8192, lowest: MusicalScale.E2, perOctave: 6),
  );

  Get.lazyPut<ChordEstimable>(() => PatternMatchingChordEstimator(
        chromaCalculable: Get.find(),
        filters: [
          ThresholdFilter(threshold: 150),
          // ThresholdFilter(threshold: 10),
          TriadChordChangeDetector(),
        ],
      ));
}
