@JS()
library audio_input;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:js/js.dart';

import 'recorder.dart';
import 'utils/loaders/audio.dart';

//ある程度大きくとらないと、処理が追いつかなくなる
@JS('start')
external Future<void> startRec([int bufferSize = 2048 * 64]);

@JS('stop')
external void stopRec();

@JS('process')
external set _processSetter(
    void Function(JSFloat32Array array, int sampleRate) f);

class WebRecorder extends Recorder {
  WebRecorder(this.timeSlice) {
    _processSetter = allowInterop(_process);
  }

  final _controller = StreamController<AudioData>.broadcast();
  final _bufferController = StreamController<List<double>>.broadcast();
  final Duration timeSlice;

  @override
  ValueNotifier<RecorderState> state = ValueNotifier(RecorderState.stopped);

  Timer? _timer;
  AudioData? _audioData;
  Float32List? _buffer;
  late int _sampleRate;

  @override
  Stream<AudioData> get stream => _controller.stream;

  @override
  Stream<List<double>> get bufferStream => _bufferController.stream;

  AudioData? get audioData => _audioData;

  void _process(JSFloat32Array array, int sampleRate) {
    final buffer = array.toDart;
    _buffer = Float32List.fromList([...?_buffer, ...buffer]);
    // final maxSize = sampleRate * 2;
    // final size = _buffer!.length;
    // if (size > maxSize) {
    //   _buffer = _buffer!.sublist(size - maxSize, maxSize);
    // }
    _bufferController.sink.add(buffer);
    _sampleRate = sampleRate;
  }

  @override
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
      _controller.sink.add(_audioData!);
      _buffer = null;
      // controller.sink.add(AudioData.empty(sampleRate: Config.sampleRate));
      // controller.sink.add(_audioData!.cutByIndex(startIndex: _seek));
      // _seek = _audioData!.buffer.length;
    });
  }

  @override
  void stop() {
    if (state.value == RecorderState.stopped) return;
    stopRec();
    _timer?.cancel();
    _buffer = null;
    state.value = RecorderState.stopped;
  }

  @override
  void dispose() {
    stop();
    _controller.close();
    _bufferController.close();
  }
}
