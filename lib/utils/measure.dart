import 'package:flutter/cupertino.dart';

mixin class Measure {
  final _stopwatch = Stopwatch();
  final Map<String, int> calculateTimes = {};

  T measure<T>(String key, T Function() f) {
    final stopwatch = Stopwatch();
    stopwatch.reset();
    stopwatch.start();
    final ret = f();
    stopwatch.stop();
    calculateTimes[key] = stopwatch.elapsedMilliseconds;
    return ret;
  }

  void printMeasuredResult() {
    calculateTimes.forEach((key, value) {
      debugPrint('$key: $value ms');
    });
  }

  void startMeasuring() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void stopMeasuring([String key = 'calc']) {
    _stopwatch.stop();
    debugPrint('$key: ${_stopwatch.elapsedMilliseconds} ms');
  }
}
