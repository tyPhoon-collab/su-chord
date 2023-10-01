import 'dart:developer';
import 'dart:io';

import 'package:chord/utils/table.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

abstract interface class Writer {
  static final debugPrint = DebugPrintWriter();

  Future<void> call(dynamic e, {String? title});
}

class DebugPrintWriter implements Writer {
  @override
  Future<void> call(e, {String? title}) async {
    log(e, name: title ?? 'writer');
  }
}

//TODO Writer to ChartWriter?
class BarChartWriter implements Writer {
  @override
  Future<void> call(e, {String? title}) async {
    if (e is! Iterable) Writer.debugPrint(e, title: title);

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
        '0'
      ],
    );
    debugPrint(result.stderr);
  }
}

abstract class HasSampleRateChartWriter implements Writer {
  const HasSampleRateChartWriter({required this.sampleRate});

  final int sampleRate;

  @override
  Future<void> call(e, {String? title}) async {
    if (e is! Iterable<Iterable>) Writer.debugPrint(e, title: title);

    final data = (e as List<List>)
        .map((e) => e.map((e) => e.toString()).toList())
        .toList();

    final fileName = const Uuid().v4();
    final file = Table(data).toCSV('test/outputs/$fileName.csv');
    debugPrint('created: ${file.path}');

    final result = await run(e, title, file);
    debugPrint(result.stderr);

    await file.delete();
    debugPrint('deleted: ${file.path}');
  }

  @protected
  Future<ProcessResult> run(e, String? title, File file);
}

class SpecChartWriter extends HasSampleRateChartWriter {
  const SpecChartWriter({required super.sampleRate});

  @override
  Future<ProcessResult> run(e, String? title, File file) =>
      Process.run(
        'python3',
        [
          'python/plots/spec.py',
          file.path,
          sampleRate.toString(),
          if (title != null) ...[
            '--title',
            title,
            '--output',
            'test/outputs/plots/$title.png',
          ],
        ],
      );
}

class ChromaChartWriter extends HasSampleRateChartWriter {
  const ChromaChartWriter({required super.sampleRate});

  @override
  Future<ProcessResult> run(e, String? title, File file) =>
      Process.run(
        'python3',
        [
          'python/plots/spec.py',
          file.path,
          sampleRate.toString(),
          if (title != null) ...[
            '--title',
            title,
            '--output',
            'test/outputs/plots/$title.png',
          ],
          '--y_axis',
          'chroma',
        ],
      );
}
