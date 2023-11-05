import 'package:flutter/foundation.dart';

import '../utils/loaders/audio.dart';
import 'stub_recorder.dart'
    if (dart.library.io) 'mobile_recorder.dart'
// if (dart.library.html) 'web_recorder.dart';
    if (dart.library.html) 'record_recorder.dart';

Recorder initRecorder() => getRecorder();

enum RecorderState {
  // paused,
  stopped,
  recording,
}

abstract interface class Recorder {
  Stream<AudioData> get stream;

  ValueNotifier<RecorderState> get state;

  Future<void> start();

  Future<void> stop();

  Future<void> dispose();

  Future<bool> request();
}

abstract interface class InputDeviceSelectable {
  Stream<Devices> get deviceStream;

  Future<void> setDevice(String id);
}

class Devices extends Iterable<DeviceInfo> {
  Devices({
    required this.current,
    required Iterable<DeviceInfo> values,
  }) : _values = values;

  final DeviceInfo current;
  final Iterable<DeviceInfo> _values;

  @override
  Iterator<DeviceInfo> get iterator => _values.iterator;
}

class DeviceInfo {
  DeviceInfo({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}
