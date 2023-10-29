import 'dart:async';

import 'package:audio_streamer/audio_streamer.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/loaders/audio.dart';
import 'recorder.dart';

Recorder getRecorder() => MobileRecorder();

class MobileRecorder implements Recorder {
  final _impl = AudioStreamer();
  final _controller = BehaviorSubject<AudioData>();

  @override
  ValueNotifier<RecorderState> state = ValueNotifier(RecorderState.stopped);

  StreamSubscription<List<double>>? _subscription;

  @override
  Stream<AudioData> get stream => _controller.stream;

  @override
  Future<void> dispose() async {
    await _subscription?.cancel();
    await _controller.close();
  }

  @override
  Future<bool> request() async {
    final state = await Permission.microphone.request();
    return state.isGranted;
  }

  @override
  Future<void> start() async {
    await request();
    await stop();
    final sr = await _impl.actualSampleRate;
    _subscription = _impl.audioStream.listen((event) {
      _controller.sink.add(AudioData(
        buffer: Float64List.fromList(event),
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
}
