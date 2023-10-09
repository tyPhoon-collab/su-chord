import 'js_external.dart';

enum RecorderState {
  stopped,
  recording,
}

typedef Recorder = WebRecorder;

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
