@JS()
library audio_input;

import 'dart:async';
import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:js/js.dart';
import 'package:js/js_util.dart';
import 'package:rxdart/rxdart.dart';

import '../utils/loaders/audio.dart';
import 'recorder.dart';

Recorder getRecorder() => WebRecorder();

//戻り値はPromise。これをpromiseToFuture関数により変換して使用する
@JS('start')
external JSPromise startRec([int bufferSize = 4096 * 128]);

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

class WebRecorder implements InputDeviceSelectable, Recorder {
  WebRecorder() {
    _processSetter = allowInterop(_process);
    _onDeviceChangedSetter = allowInterop(_onDeviceChanged);
  }

  final _controller = BehaviorSubject<AudioData>();
  final _deviceController = BehaviorSubject<Devices>();

  @override
  ValueNotifier<RecorderState> state = ValueNotifier(RecorderState.stopped);

  @override
  Stream<AudioData> get stream => _controller.stream;

  @override
  Stream<Devices> get deviceStream => _deviceController.stream;

  void _process(JSFloat32Array array, int sampleRate) {
    final audioData = AudioData(
      buffer: Float64List.fromList(array.toDart),
      sampleRate: sampleRate,
    );
    _controller.sink.add(audioData);
  }

  //TODO 開始できなかった時の処理
  @override
  Future<void> start() async {
    if (state.value == RecorderState.recording) return;
    await promiseToFuture(startRec());
    state.value = RecorderState.recording;
  }

  @override
  Future<void> stop() async {
    if (state.value == RecorderState.recording) {
      stopRec();
      state.value = RecorderState.stopped;
    }
  }

  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
    await _deviceController.close();
  }

  @override
  Future<bool> request() async {
    requestRec();
    return true;
  }

  @override
  Future<void> setDevice(String id) async {
    await promiseToFuture(setDeviceId(id));
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
}
