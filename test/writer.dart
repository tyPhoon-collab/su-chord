import 'dart:io';

import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/histogram.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import 'util.dart';

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

bool hideTitle = false;

class BarChartWriter {
  const BarChartWriter();

  Future<void> call(Iterable<num> data, {String? title}) async {
    final result = await Process.run(
      _python,
      [
        'python/plot/bar.py',
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
        'python/plot/bar.py',
        ...data.map((e) => e.toString()),
        ..._createTitleArgs(title),
        ..._createLimitArgs(_Axis.y, 0, 1),
        '--x_label_type',
        'pcp',
      ],
    );
    _debugPrintIfNotEmpty(result.stderr);
  }
}

class PitchChartWriter {
  const PitchChartWriter();

  Future<void> call(Iterable<num> data, {String? title}) async {
    final result = await Process.run(
      _python,
      [
        'python/plot/bar.py',
        ...data.map((e) => e.toString()),
        ..._createTitleArgs(title),
        '--x_label_type',
        'pitch',
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

  Future<void> runWithMultiTempCSVFiles(
    List<Table> tables,
    Future<ProcessResult> Function(List<String> filePaths) run,
  ) async {
    final files = await Future.wait(tables.map(_createTempFile));

    final result = await run(files.map((e) => e.path).toList());

    _debugPrintIfNotEmpty(result.stdout);
    _debugPrintIfNotEmpty(result.stderr);

    await Future.wait(files.map(_deleteFile));
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
    String? xLabel,
    String? yLabel,
  }) async =>
      runWithTempCSVFile(
        Table([
          x.map((e) => e.toString()).toList(),
          y.map((e) => e.toString()).toList(),
        ]),
        (filePath) => Process.run(
          _python,
          [
            'python/plot/line.py',
            filePath,
            ..._createTitleArgs(title),
            ..._createLimitArgs(_Axis.x, xMin, xMax),
            ..._createLimitArgs(_Axis.y, yMin, yMax),
            ..._createLabelArgs(_Axis.x, xLabel),
            ..._createLabelArgs(_Axis.y, yLabel),
          ],
        ),
      );
}

class LibROSASpecShowContext {
  const LibROSASpecShowContext({
    required this.sampleRate,
    required this.chunkSize,
    required this.chunkStride,
  });

  LibROSASpecShowContext.of(EstimatorFactoryContext context)
      : sampleRate = context.sampleRate,
        chunkSize = context.chunkSize,
        chunkStride = context.chunkStride;

  final int sampleRate;
  final int chunkSize;
  final int chunkStride;
}

/// LibROSA based
class SpecChartWriter with _UsingTempCSVFileChartWriter {
  const SpecChartWriter(this._context, {this.yAxis});

  const SpecChartWriter.chroma(this._context) : yAxis = 'chroma';

  final LibROSASpecShowContext _context;

  final String? yAxis;

  Future<void> call(
    Iterable<Iterable<num>> data, {
    String? title,
    num? yMin,
    num? yMax,
  }) async =>
      runWithTempCSVFile(
        Table.fromMatrix(data),
        (filePath) => Process.run(
          _python,
          [
            'python/plot/spec.py',
            filePath,
            _context.sampleRate.toString(),
            _context.chunkSize.toString(),
            _context.chunkStride.toString(),
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
        Table.fromPoints(data),
        (filePath) => Process.run(
          _python,
          [
            'python/plot/scatter.py',
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
        Table.fromPoints(data),
        (filePath) => Process.run(
          _python,
          [
            'python/plot/hist2d.py',
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
      runWithMultiTempCSVFiles(
        [
          correct.toTable(),
          predict.toTable(),
        ],
        (filePaths) => Process.run(
          _python,
          [
            'python/plot/hcdf.py',
            filePaths[0],
            filePaths[1],
            ..._createTitleArgs(title),
          ],
        ),
      );
}

class HCDFDetailChartWriter with _UsingTempCSVFileChartWriter {
  const HCDFDetailChartWriter(this._context);

  final LibROSASpecShowContext _context;

  Future<void> call(
    ChordProgression<Chord> correct,
    ChordProgression<Chord> predict,
    List<Chroma> chromas, {
    String? title,
  }) async =>
      runWithMultiTempCSVFiles(
        [
          correct.toTable(),
          predict.toTable(),
          Table(chromas.map((e) => e.toRow()).toList()),
        ],
        (filePaths) => Process.run(
          _python,
          [
            'python/plot/hcdf.py',
            filePaths[0],
            filePaths[1],
            '--chromas_path',
            filePaths[2],
            '--sample_rate',
            _context.sampleRate.toString(),
            '--win_length',
            _context.chunkSize.toString(),
            '--hop_length',
            _context.chunkStride.toString(),
            ..._createTitleArgs(title),
          ],
        ),
      );
}

typedef _Args = List<String>;

enum _Axis { x, y }

_Args _createTitleArgs(String? title, [String extension = 'pdf']) => [
      if (title != null) ...[
        if (!hideTitle) ...[
          '--title',
          title,
        ],
        '--output',
        'test/outputs/plots/${title.sanitize()}.$extension',
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

_Args _createLabelArgs(_Axis limitAxis, String? label) => [
      if (label != null) ...[
        '--${limitAxis.name}_label',
        label,
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
