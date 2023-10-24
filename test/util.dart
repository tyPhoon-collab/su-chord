import 'dart:io';

import 'package:chord/domains/chord_progression.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/foundation.dart';

class AudioStreamEmulator {
  const AudioStreamEmulator({
    this.bufferChunkSize = 22050,
    this.sleepDuration = const Duration(seconds: 1),
  });

  final int bufferChunkSize;
  final Duration sleepDuration;

  Stream<AudioData> stream(AudioData data) async* {
    int seek = 0;

    while (seek < data.buffer.length) {
      final chunkData = data.cutByIndex(seek, seek + bufferChunkSize);
      seek += bufferChunkSize;
      yield chunkData;
      sleep(sleepDuration);
    }
  }
}

void printProgressions(
  ChordProgression progression, [
  ChordProgression? corrects,
]) {
  if (corrects != null) {
    printProgression('corrects', corrects);
  }
  printProgression('predicts', progression.simplify());
  printProgression('predict all', progression);
}

void printProgression(String label, ChordProgression progression) {
  debugPrint('$label(${progression.length})\t: $progression');
}

void printSeparation() {
  debugPrint('-' * 20);
}
