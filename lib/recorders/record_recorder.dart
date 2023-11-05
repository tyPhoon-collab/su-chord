import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/loaders/audio.dart';
import 'recorder.dart';

Recorder getRecorder() => RecordRecorder();

class RecordRecorder implements Recorder {
  final _impl = AudioRecorder();
  final _controller = BehaviorSubject<AudioData>();

  @override
  ValueNotifier<RecorderState> state = ValueNotifier(RecorderState.stopped);

  StreamSubscription<Uint8List>? _subscription;

  @override
  Stream<AudioData> get stream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  @override
  Future<bool> request() async {
    return _impl.hasPermission();
  }

  @override
  Future<void> start() async {
    await request();
    await stop();

    const sr = 22050;
    final stream = await _impl.startStream(const RecordConfig(
      encoder: AudioEncoder.pcm16bits,
      numChannels: 1,
      sampleRate: 22050,
    ));
    _subscription = stream.listen((event) {
      _controller.sink.add(AudioData(
        buffer: _convert(event),
        sampleRate: sr,
      ));
    });
    state.value = RecorderState.recording;
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    state.value = RecorderState.stopped;
  }

  Float64List _convert(Uint8List bytes) {
    final float64Data = Float64List(bytes.length ~/ 2);
    final data = ByteData.view(bytes.buffer);

    for (int i = 0; i < bytes.length; i += 2) {
      final pcmValue = data.getInt16(i, Endian.host);
      final floatValue = pcmValue / 32768.0;

      float64Data[i ~/ 2] = floatValue;
    }
    return float64Data;
  }
}
