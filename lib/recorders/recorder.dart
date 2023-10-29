import 'package:flutter/foundation.dart';

import '../utils/loaders/audio.dart';

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

  Future<void> request();
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

// //TODO 適切なシグネチャを考える
// //モバイルアプリ化する場合など。ライブラリに依存するので、今考える必要はない
// abstract class Recorder {
//
// }
