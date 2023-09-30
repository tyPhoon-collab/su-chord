import 'package:flutter/foundation.dart';

import 'utils/loaders/audio.dart';

enum RecorderState {
  stopped,
  recording,
}

//TODO 適切なシグネチャを考える
abstract class Recorder {
  Future<void> start();

  void stop();

  void dispose();

  ValueNotifier<RecorderState> get state;

  Stream<AudioData> get stream;

  bool get isRecording => state.value == RecorderState.recording;
}
