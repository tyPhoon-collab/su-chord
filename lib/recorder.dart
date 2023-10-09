import 'package:flutter/foundation.dart';

import 'utils/loaders/audio.dart';

enum RecorderState {
  stopped,
  recording,
}

//TODO 適切なシグネチャを考える
//モバイルアプリ化する場合など。ライブラリに依存するので、今考える必要はない
abstract class Recorder {
  Future<void> start();

  void stop();

  void dispose();

  ValueNotifier<RecorderState> get state;

  Stream<AudioData> get stream;

  Stream<List<double>> get bufferStream;

  bool get isRecording => state.value == RecorderState.recording;
}
