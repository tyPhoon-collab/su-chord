import 'dart:io';

import 'package:chord/utils/table.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

void _debugPrintIfNotEmpty(dynamic output) {
  if (output is String && output.isNotEmpty) {
    debugPrint(output);
  } else {
    debugPrint(output);
  }
}

abstract interface class Writer {
  static const debugPrint = DebugPrintWriter();

  Future<void> call(dynamic e, {String? title});
}

class DebugPrintWriter implements Writer {
  const DebugPrintWriter();

  @override
  Future<void> call(e, {String? title}) async {
    debugPrint('[${title ?? 'log'}] $e');
  }
}

//TODO Writer to ChartWriter?
class BarChartWriter implements Writer {
  const BarChartWriter();

  @override
  Future<void> call(e, {String? title}) async {
    if (e is! Iterable) {
      Writer.debugPrint(e, title: title);
      return;
    }
    final result = await Process.run(
      'python3',
      [
        'python/plots/bar.py',
        ...e.map((e) => e.toString()),
        if (title != null) ...[
          '--title',
          title,
          '--output',
          'test/outputs/plots/$title.png',
        ],
        '--ymax',
        '1',
        '--ymin',
        '0',
      ],
    );
    _debugPrintIfNotEmpty(result.stderr);
  }
}

class PCPChartWriter implements Writer {
  const PCPChartWriter();

  @override
  Future<void> call(e, {String? title}) async {
    if (e is! Iterable) {
      Writer.debugPrint(e, title: title);
      return;
    }
    final result = await Process.run(
      'python3',
      [
        'python/plots/bar.py',
        ...e.map((e) => e.toString()),
        if (title != null) ...[
          '--title',
          title,
          '--output',
          'test/outputs/plots/$title.png',
        ],
        '--ymax',
        '1',
        '--ymin',
        '0',
        '--pcp',
      ],
    );
    _debugPrintIfNotEmpty(result.stderr);
  }
}

abstract class UsingTempCSVFileChartWriter implements Writer {
  const UsingTempCSVFileChartWriter();

  @override
  Future<void> call(e, {String? title}) async {
    if (e is! Iterable<Iterable>) {
      Writer.debugPrint(e, title: title);
      return;
    }
    final data = (e as List<Iterable>)
        .map((e) => e.map((e) => e.toString()).toList())
        .toList();

    final fileName = const Uuid().v4();
    final file = Table(data).toCSV('test/outputs/$fileName.csv');
    debugPrint('created: ${file.path}');

    final result = await run(e, title, file);
    _debugPrintIfNotEmpty(result.stdout);
    _debugPrintIfNotEmpty(result.stderr);

    await file.delete();
    debugPrint('deleted: ${file.path}');
  }

  @protected
  Future<ProcessResult> run(e, String? title, File file);
}

class LineChartWriter extends UsingTempCSVFileChartWriter {
  const LineChartWriter();

  @override
  Future<ProcessResult> run(e, String? title, File file) => Process.run(
        'python3',
        [
          'python/plots/line.py',
          file.path,
          if (title != null) ...[
            '--title',
            title,
            '--output',
            'test/outputs/plots/$title.png',
          ]
        ],
      );
}

class SpecChartWriter extends UsingTempCSVFileChartWriter {
  const SpecChartWriter({
    required this.sampleRate,
    required this.chunkSize,
    required this.chunkStride,
    this.yAxis,
  });

  const SpecChartWriter.chroma({
    required this.sampleRate,
    required this.chunkSize,
    required this.chunkStride,
  }) : yAxis = 'chroma';

  final int sampleRate;
  final int chunkSize;
  final int chunkStride;
  final String? yAxis;

  @override
  Future<ProcessResult> run(e, String? title, File file) => Process.run(
        'python3',
        [
          'python/plots/spec.py',
          file.path,
          sampleRate.toString(),
          chunkSize.toString(),
          chunkStride.toString(),
          if (title != null) ...[
            '--title',
            title,
            '--output',
            'test/outputs/plots/$title.png',
          ],
          if (yAxis case final String yAxis) ...[
            '--y_axis',
            yAxis,
          ]
        ],
      );
}
