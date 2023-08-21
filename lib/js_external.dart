@JS()
library audio_input;

import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:js/js.dart';

import 'utils/loader.dart';

//現状、bufferSizeはバイトの長さを指す。
@JS('start')
external Future<void> startRec([int bufferSize = 4096 * 8]);

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
  RecorderState _state = RecorderState.stopping;
  Timer? _timer;
  AudioData? _audioData;
  Float32List? _buffer;
  late int _sampleRate;

  RecorderState get state => _state;

  bool get isRecording => _state == RecorderState.recording;

  Stream<AudioData> get stream => controller.stream;

  AudioData? get audioData => _audioData;

  void _process(JSFloat32Array array, int sampleRate) {
    var buffer = [...?_buffer, ...array.toDart];
    final maxSize = sampleRate * 3;
    final size = buffer.length;
    if (size > maxSize) {
      buffer = buffer.sublist(size - maxSize, maxSize);
    }
    _buffer = Float32List.fromList(buffer);
    _sampleRate = sampleRate;
    if (_timer == null) {
      _startTimer();
    }
  }

  Future<void> start() async {
    if (isRecording) return;
    await startRec();
    _state = RecorderState.recording;
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

  /// TODO returns an URL pointing to the recording.
  void stop() {
    if (_state == RecorderState.stopping) return;
    stopRec();
    _timer?.cancel();
    _buffer = null;
    _state = RecorderState.stopping;
  }

  void dispose() {
    stop();
    controller.close();
  }
}
