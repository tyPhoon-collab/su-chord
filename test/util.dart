import 'dart:io';

import 'package:chord/utils/loaders/audio.dart';

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
