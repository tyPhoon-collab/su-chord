import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'recorders/recorder.dart';

part 'recorder_service.g.dart';

@riverpod
class GlobalRecorder extends _$GlobalRecorder {
  @override
  Recorder build() {
    ref.onDispose(() {
      state.dispose();
    });
    return initRecorder();
  }

  void set(Recorder newValue) {
    state.dispose();
    state = newValue;
  }
}
