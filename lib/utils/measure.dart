import 'package:flutter/cupertino.dart';

typedef CalculateTimeTable = Map<String, int>;

mixin class Measure {
  static Function? logger = debugPrint;

  final _stopwatch = Stopwatch();
  final CalculateTimeTable calculateTimes = {};

  T measure<T>(String key, T Function() f) {
    final stopwatch = Stopwatch()..start();
    final ret = f();
    stopwatch.stop();
    calculateTimes[key] = stopwatch.elapsedMilliseconds;
    return ret;
  }

  void printMeasuredResult() {
    calculateTimes.forEach((key, value) {
      logger?.call('$key: $value ms');
    });
  }

  void startMeasuring() {
    _stopwatch.reset();
    _stopwatch.start();
  }

  void stopMeasuring([String key = 'calc']) {
    _stopwatch.stop();
    logger?.call('$key: ${_stopwatch.elapsedMilliseconds} ms');
  }
}

class CalculateTimeTableView extends StatelessWidget {
  const CalculateTimeTableView({
    super.key,
    required this.table,
  });

  final CalculateTimeTable table;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: table.entries
            .map((e) => Text(
                  '${e.key}: ${e.value} ms',
                ))
            .toList(),
      );
}
