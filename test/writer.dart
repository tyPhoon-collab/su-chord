import 'dart:io';

import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/utils/histogram.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

typedef LogTest = void Function(Object e, {String? title});

//develop.logはtestモードでは機能しない
//logのような機能をdebugPrintで代用した関数
//Objectで受け取れる
void logTest(Object e, {String? title}) {
  debugPrint('[${title ?? 'log'}] $e');
}

///仮想環境を使わない場合は、通常のpythonコマンドを用いる
// const _python = 'python3';
const _python = '.venv/bin/python';

class BarChartWriter {
  const BarChartWriter();

  Future<void> call(Iterable<num> data, {String? title}) async {
    final result = await Process.run(
      _python,
      [
        'python/plots/bar.py',
        ...data.map((e) => e.toString()),
        ..._createTitleArgs(title),
      ],
    );
    _debugPrintIfNotEmpty(result.stderr);
  }
}

class PCPChartWriter {
  const PCPChartWriter();

  Future<void> call(Iterable<num> data, {String? title}) async {
    final result = await Process.run(
      _python,
      [
        'python/plots/bar.py',
        ...data.map((e) => e.toString()),
        ..._createTitleArgs(title),
        ..._createLimitArgs(_Axis.y, 0, 1),
        '--pcp',
      ],
    );
    _debugPrintIfNotEmpty(result.stderr);
  }
}

mixin class _UsingTempCSVFileChartWriter {
  Future<void> runWithTempCSVFile(
    Table table,
    Future<ProcessResult> Function(String filePath) run,
  ) async {
    final file = await _createTempFile(table);

    final result = await run(file.path);
    _debugPrintIfNotEmpty(result.stdout);
    _debugPrintIfNotEmpty(result.stderr);

    await _deleteFile(file);
  }

  Future<void> runWithTwoTempCSVFiles(
    Table table1,
    Table table2,
    Future<ProcessResult> Function(String filePath1, String filePath2) run,
  ) async {
    final file1 = await _createTempFile(table1);
    final file2 = await _createTempFile(table2);

    final result = await run(file1.path, file2.path);
    _debugPrintIfNotEmpty(result.stdout);
    _debugPrintIfNotEmpty(result.stderr);

    await _deleteFile(file1);
    await _deleteFile(file2);
  }

  Future<File> _createTempFile(Table table) async {
    final fileName = const Uuid().v4();
    final file = await table.toCSV('test/outputs/$fileName.csv');
    debugPrint('created: ${file.path}');
    return file;
  }

  Future<void> _deleteFile(File file) async {
    await file.delete();
    debugPrint('deleted: ${file.path}');
  }
}

class LineChartWriter with _UsingTempCSVFileChartWriter {
  const LineChartWriter();

  Future<void> call(
    Iterable<num> x,
    Iterable<num> y, {
    String? title,
    num? xMin,
    num? xMax,
    num? yMin,
    num? yMax,
  }) async =>
      runWithTempCSVFile(
        Table([
          x.map((e) => e.toString()).toList(),
          y.map((e) => e.toString()).toList(),
        ]),
        (filePath) => Process.run(
          _python,
          [
            'python/plots/line.py',
            filePath,
            ..._createTitleArgs(title),
            ..._createLimitArgs(_Axis.x, xMin, xMax),
            ..._createLimitArgs(_Axis.y, yMin, yMax),
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

  Future<void> call(
    Iterable<Iterable<num>> data, {
    String? title,
    num? yMin,
    num? yMax,
  }) async =>
      runWithTempCSVFile(
        Table(data.map((e) => e.map((e) => e.toString()).toList()).toList()),
        (filePath) => Process.run(
          _python,
          [
            'python/plots/spec.py',
            filePath,
            sampleRate.toString(),
            chunkSize.toString(),
            chunkStride.toString(),
            ..._createTitleArgs(title),
            ..._createLimitArgs(_Axis.y, yMin, yMax),
            if (yAxis case final String yAxis) ...[
              '--y_axis',
              yAxis,
            ],
          ],
        ),
      );
}

class ScatterChartWriter with _UsingTempCSVFileChartWriter {
  const ScatterChartWriter();

  Future<void> call(Iterable<Point> data, {String? title}) async =>
      runWithTempCSVFile(
        data.toTable(),
        (filePath) => Process.run(
          _python,
          [
            'python/plots/scatter.py',
            filePath,
            ..._createTitleArgs(title),
          ],
        ),
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
        data.toTable(),
        (filePath) => Process.run(
          _python,
          [
            'python/plots/hist2d.py',
            filePath,
            ..._createTitleArgs(title),
            ..._createBinArgs(_Axis.x, xBin),
            ..._createBinArgs(_Axis.y, yBin),
          ],
        ),
      );
}

class HCDFChartWriter with _UsingTempCSVFileChartWriter {
  const HCDFChartWriter();

  Future<void> call(
    ChordProgression<Chord> correct,
    ChordProgression<Chord> predict, {
    String? title,
  }) async =>
      runWithTwoTempCSVFiles(
        correct.toTable(),
        predict.toTable(),
        (filePath1, filePath2) => Process.run(
          _python,
          [
            'python/plots/hcdf.py',
            filePath1,
            filePath2,
            ..._createTitleArgs(title),
          ],
        ),
      );
}

typedef _Args = List<String>;

enum _Axis { x, y }

_Args _createTitleArgs(String? title) => [
      if (title != null) ...[
        '--title',
        title,
        '--output',
        'test/outputs/plots/$title.png',
      ],
    ];

_Args _createLimitArgs(_Axis limitAxis, num? min, num? max) => [
      if (min != null) ...[
        '--${limitAxis.name}_min',
        min.toString(),
      ],
      if (max != null) ...[
        '--${limitAxis.name}_max',
        max.toString(),
      ],
    ];

_Args _createBinArgs(_Axis axis, Bin? bin) => [
      if (bin != null) ...[
        '--${axis.name}_bin',
        ...bin.map((e) => e.toString()),
      ],
    ];

void _debugPrintIfNotEmpty(dynamic output) {
  if (output is String && output.isNotEmpty) {
    debugPrint(output);
  }
}

extension _PointsToTable on Iterable<Point> {
  Table toTable() => Table(
        map((e) => [
              e.x.toString(),
              e.y.toString(),
              e.weight.toString(),
            ]).toList(),
        header: ['x', 'y', 'c'],
      );
}
