@JS()
library audio_input;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';

import 'utils/loader.dart';

//現状、bufferSizeはバイトの長さを指す。
//ある程度大きくとらないと、処理が追いつかなくなる
@JS('start')
external Future<void> startRec([int bufferSize = 8192 * 8]);

@JS('stop')
external void stopRec();

@JS('process')
external set _processSetter(
    void Function(JSFloat32Array array, int sampleRate) f);

enum RecorderState {
  stopping,
  recording,
}

class WebRecorder {
  WebRecorder(this.timeSlice) {
    _processSetter = allowInterop(_process);
  }

  final controller = StreamController<AudioData>();
  final Duration timeSlice;
  ValueNotifier<RecorderState> state = ValueNotifier(RecorderState.stopping);
  Timer? _timer;
  AudioData? _audioData;
  Float32List? _buffer;
  late int _sampleRate;

  bool get isRecording => state.value == RecorderState.recording;

  Stream<AudioData> get stream => controller.stream;

  AudioData? get audioData => _audioData;

  void _process(JSFloat32Array array, int sampleRate) {
    _buffer = Float32List.fromList([...?_buffer, ...array.toDart]);
    final maxSize = sampleRate * 3;
    final size = _buffer!.length;
    if (size > maxSize) {
      _buffer = _buffer!.sublist(size - maxSize, maxSize);
    }
    _sampleRate = sampleRate;
  }

  Future<void> start() async {
    if (isRecording) return;
    await startRec();
    _startTimer();
    state.value = RecorderState.recording;
  }

  void _startTimer() {
    _timer = Timer.periodic(timeSlice, (timer) {
      if (_buffer == null) return;
      _audioData = AudioData(
        buffer: Float64List.fromList(_buffer!),
        sampleRate: _sampleRate,
      );
      controller.sink.add(_audioData!);
      // controller.sink.add(_audioData!.cutByIndex(startIndex: _seek));
      // _seek = _audioData!.buffer.length;
    });
  }

  void stop() {
    if (state.value == RecorderState.stopping) return;
    stopRec();
    _timer?.cancel();
    _buffer = null;
    state.value = RecorderState.stopping;
  }

  void dispose() {
    stop();
    controller.close();
  }
}
