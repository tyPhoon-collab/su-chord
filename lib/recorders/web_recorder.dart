@JS()
library audio_input;

import 'dart:async';
import 'dart:js_interop';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/loaders/audio.dart';
import 'recorder.dart';

//戻り値はPromise。これをpromiseToFuture関数により変換して使用する
@JS('start')
external JSPromise startRec([int bufferSize = 2048 * 64]);

@JS('stop')
external void stopRec();

//TODO 許可を得たかどうかを戻り値で取得できるようにする
@JS('request')
external void requestRec();

@JS('getDeviceInfo')
external JSPromise getDeviceInfo();

@JS('setDeviceId')
external JSPromise setDeviceId(String id);

@JS('process')
external set _processSetter(
    void Function(JSFloat32Array array, int sampleRate) f);

@JS('onDeviceChanged')
external set _onDeviceChangedSetter(
    void Function(List<dynamic> list, String? curretnId) f);

@JS()
@staticInterop
class MediaDeviceInfo {}

extension on MediaDeviceInfo {
  external String deviceId;
  external String groupId;
  external String kind;
  external String label;
}

class WebRecorder {
  WebRecorder(this.timeSlice) {
    _processSetter = allowInterop(_process);
    _onDeviceChangedSetter = allowInterop(_onDeviceChanged);
  }

  final _controller = BehaviorSubject<AudioData>();
  final _bufferController = BehaviorSubject<List<double>>();
  final _deviceController = BehaviorSubject<Devices>();
  final Duration timeSlice;

  ValueNotifier<RecorderState> state = ValueNotifier(RecorderState.stopped);

  Timer? _timer;
  AudioData? _audioData;
  Float32List? _buffer;
  late int _sampleRate;

  Stream<AudioData> get stream => _controller.stream;

  Stream<List<double>> get bufferStream => _bufferController.stream;

  Stream<Devices> get deviceStream => _deviceController.stream;

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

  void _onDeviceChanged(List<dynamic> list, String? currentId) {
    final devices = list
        .cast<MediaDeviceInfo>()
        .map((e) => DeviceInfo(id: e.deviceId, label: e.label))
        .toList();

    final current =
        devices.firstWhereOrNull((e) => e.id == currentId) ?? devices.first;

    _deviceController.sink.add(Devices(current: current, values: devices));
  }

  //TODO 開始できなかった時の処理
  Future<void> start() async {
    if (state.value == RecorderState.recording) return;
    await promiseToFuture(startRec());
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

  void stop() {
    if (state.value == RecorderState.stopped) return;
    stopRec();
    _timer?.cancel();
    _buffer = null;
    state.value = RecorderState.stopped;
  }

  void dispose() {
    stop();
    _controller.close();
    _bufferController.close();
    _deviceController.close();
  }

  void request() {
    requestRec();
  }

  Future<void> setDevice(String id) async {
    await promiseToFuture(setDeviceId(id));
  }
}
