import 'dart:io';

import 'package:chord/utils/histogram.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

typedef LogTest = void Function(Object e, {String? title});

//develop.logはtestモードでは機能しない
//logのような機能をdebugPrintで代用した関数
void logTest(Object e, {String? title}) {
  debugPrint('[${title ?? 'log'}] $e');
}

//TODO Writer to ChartWriter?
class BarChartWriter {
  const BarChartWriter();

  Future<void> call(Iterable<num> data, {String? title}) async {
    final result = await Process.run(
      'python3',
      [
        'python/plots/bar.py',
        ...data.map((e) => e.toString()),
        if (title != null) ...[
          '--title',
          title,
          '--output',
          'test/outputs/plots/$title.png',
        ],
      ],
    );
    _debugPrintIfNotEmpty(result.stderr);
  }
}

class PCPChartWriter {
  const PCPChartWriter();

  Future<void> call(Iterable<num> data, {String? title}) async {
    final result = await Process.run(
      'python3',
      [
        'python/plots/bar.py',
        ...data.map((e) => e.toString()),
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

mixin class _UsingTempCSVFileChartWriter {
  Future<void> runWithTempCSVFile(
    List<List<String>> data,
    Future<ProcessResult> Function(String filePath) run, {
    Header? header,
  }) async {
    final fileName = const Uuid().v4();
    final file = Table(
      data,
      header: header,
    ).toCSV('test/outputs/$fileName.csv');
    final filePath = file.path;
    debugPrint('created: $filePath');

    final result = await run(filePath);
    _debugPrintIfNotEmpty(result.stdout);
    _debugPrintIfNotEmpty(result.stderr);

    await file.delete();
    debugPrint('deleted: $filePath');
  }
}

class LineChartWriter with _UsingTempCSVFileChartWriter {
  const LineChartWriter();

  Future<void> call(Iterable<Iterable<num>> data, {String? title}) async =>
      runWithTempCSVFile(
        data.map((e) => e.map((e) => e.toString()).toList()).toList(),
        (filePath) => Process.run(
          'python3',
          [
            'python/plots/line.py',
            filePath,
            if (title != null) ...[
              '--title',
              title,
              '--output',
              'test/outputs/plots/$title.png',
            ]
          ],
        ),
      );
}

/// LibROSA based
class SpecChartWriter with _UsingTempCSVFileChartWriter {
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

  Future<void> call(Iterable<Iterable<num>> data, {String? title}) async =>
      runWithTempCSVFile(
        data.map((e) => e.map((e) => e.toString()).toList()).toList(),
        (filePath) => Process.run(
          'python3',
          [
            'python/plots/spec.py',
            filePath,
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
        ),
      );
}

class ScatterChartWriter with _UsingTempCSVFileChartWriter {
  const ScatterChartWriter();

  Future<void> call(Iterable<Point> data, {String? title}) async =>
      runWithTempCSVFile(
        data
            .map((e) => [e.x.toString(), e.y.toString(), e.weight.toString()])
            .toList(),
        (filePath) => Process.run(
          'python3',
          [
            'python/plots/scatter.py',
            filePath,
            if (title != null) ...[
              '--title',
              title,
              '--output',
              'test/outputs/plots/$title.png',
            ]
          ],
        ),
        header: ['x', 'y', 'c'],
      );
}

class Hist2DChartWriter with _UsingTempCSVFileChartWriter {
  const Hist2DChartWriter();

  Future<void> call(
    Iterable<Point> data, {
    required Bin xBin,
    required Bin yBin,
    String? title,
  }) async =>
      runWithTempCSVFile(
        data
            .map((e) => [e.x.toString(), e.y.toString(), e.weight.toString()])
            .toList(),
        (filePath) => Process.run(
          'python3',
          [
            'python/plots/hist2d.py',
            filePath,
            '--x_bin',
            ...xBin.map((e) => e.toString()),
            '--y_bin',
            ...yBin.map((e) => e.toString()),
            if (title != null) ...[
              '--title',
              title,
              '--output',
              'test/outputs/plots/$title.png',
            ]
          ],
        ),
        header: ['x', 'y', 'c'],
      );
}

void _debugPrintIfNotEmpty(dynamic output) {
  if (output is String && output.isNotEmpty) {
    debugPrint(output);
  }
}
