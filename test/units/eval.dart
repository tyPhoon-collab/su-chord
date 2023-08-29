import 'dart:io';

import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chord_selector.dart';
import 'package:chord/domains/estimate.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loader.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

//Song ID : ChordProgression
typedef _CorrectChords = Map<String, ChordProgression>;
typedef _SongID = String;
typedef _Paths = Iterable<String>;

const sampleRate = 22050;
final factory2048_1024 = EstimatorFactory(const EstimatorFactoryContext(
  chunkSize: 2048,
  chunkStride: 1024,
  sampleRate: sampleRate,
));

final factory8192_0 = EstimatorFactory(const EstimatorFactoryContext(
  chunkSize: 8192,
  chunkStride: 0,
  sampleRate: sampleRate,
));

Future<void> main() async {
  _Evaluator.bypassCsvWriting = true;

  final corrects = await _getCorrectChords();
  final loaders = Map.fromEntries([
    ...await _getFiles('assets/evals/Halion_CleanGuitarVX')
        .then((files) => files.map(_parsePathToMapEntries)),
    ...await _getFiles('assets/evals/Halion_CleanStratGuitar')
        .then((files) => files.map(_parsePathToMapEntries)),
    ...await _getFiles('assets/evals/HojoGuitar')
        .then((files) => files.map(_parsePathToMapEntries)),
    ...await _getFiles('assets/evals/RealStrat')
        .then((files) => files.map(_parsePathToMapEntries)),
  ]);
  final data = <_EvaluatorContext>[];

  setUpAll(() async {
    for (final entry in loaders.entries) {
      final songId = entry.key;
      final key = songId.split('_').first;
      data.add(
        _EvaluatorContext(
          key: int.parse(key),
          songId: songId,
          data: await entry.value.load(duration: 83, sampleRate: sampleRate),
          corrects: corrects[key]!,
        ),
      );
    }
    data.sort((a, b) => a.compareTo(b));
  });

  group('prop', () {
    test('main', () async {
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory2048_1024.guitarRange.reassignment,
          filters: factory2048_1024.filter.eval,
        ),
      ).evaluate(data, path: 'test/outputs/prop.csv');
    });

    test('prop to conv chunkSize', () async {
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.reassignment,
          filters: factory8192_0.filter.eval,
        ),
      ).evaluate(data, path: 'test/outputs/prop.csv');
    });

    test('piano tuning', () async {
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory2048_1024.bigRange.reassignment,
          filters: factory2048_1024.filter.eval,
        ),
      ).evaluate(data);
    });
  });

  group('conv', () {
    test('comb + search tree', () async {
      _Evaluator(
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          thresholdRatio: 0.3,
        ),
      ).evaluate(data, path: 'test/outputs/conv.csv');
    });

    test('_comb + search tree + db', () async {
      final progressions = await ChordProgressionDBChordSelector.load(
          'assets/csv/chord_progression.csv');
      _Evaluator(
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          thresholdRatio: 0.3,
          chordSelectable:
              ChordProgressionDBChordSelector(progressions: progressions),
        ),
      ).evaluate(data, path: 'test/outputs/conv_db.csv');
    });
  });

  group('control experiment', () {
    test('pattern matching + comb filter', () {
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
        ),
      ).evaluate(data);
    });

    test('search tree + reassignment', () async {
      _Evaluator(
          estimator: SearchTreeChordEstimator(
        chromaCalculable: factory8192_0.guitarRange.reassignment,
        filters: factory8192_0.filter.eval,
        thresholdRatio: 0.5,
      )).evaluate(data);
    });
  });
}

class _EvaluatorContext implements Comparable<_EvaluatorContext> {
  const _EvaluatorContext({
    required this.key,
    required this.songId,
    required this.data,
    required this.corrects,
  });

  ///ソート用の変数
  final int key;
  final _SongID songId;
  final AudioData data;
  final ChordProgression corrects;

  @override
  int compareTo(_EvaluatorContext other) {
    return key.compareTo(other.key);
  }
}

class _Evaluator {
  _Evaluator({required this.estimator});

  static bool bypassCsvWriting = false;

  final ChordEstimable estimator;
  Table? table;

  void evaluate(Iterable<_EvaluatorContext> context, {String? path}) {
    assert(path == null || path.endsWith('.csv'));
    if (path != null) {
      if (!bypassCsvWriting) {
        table = Table.empty();
      } else {
        debugPrint('CSV writing is bypassing');
      }
    }

    _evaluate(context);

    if (path != null) table?.toCSV(path);
  }

  void _evaluate(Iterable<_EvaluatorContext> context) {
    final sum = context.map(_evaluateOne).sum;
    final correctRate = sum / context.length * 100;
    debugPrint('corrects: ${correctRate.toStringAsFixed(3)}%');
  }

  double _evaluateOne(_EvaluatorContext context) {
    final data = context.data;
    final corrects = context.corrects;
    final chords = estimator.estimate(data);

    debugPrint(corrects.toString());
    debugPrint(chords.toString());

    table?.add(corrects.toCSVRow()..insert(0, '${context.songId}_correct'));
    table?.add(chords.toCSVRow()..insert(0, '${context.songId}_estimate'));

    return chords.consistencyRate(corrects);
  }
}

Future<_Paths> _getFiles(String path) async {
  final directory = Directory(path);

  if (!directory.existsSync()) {
    throw ArgumentError('Not exists $path');
  }

  final files = directory.listSync();

  return files.whereType<File>().map((e) => e.path);
}

///ファイル名が/{song_id}_{identify}のフォーマットに沿っていると仮定している
MapEntry<_SongID, AudioLoader> _parsePathToMapEntries(String path) {
  final parts = path.split(Platform.pathSeparator);
  final source = parts[parts.length - 2];
  final num = parts.last.split('_').first;
  final songId = '${num}_$source';
  return MapEntry(songId, SimpleAudioLoader(path: path));
}

Future<_CorrectChords> _getCorrectChords() async {
  final fields = await CSVLoader.corrects.load();

  //ignore header
  return Map.fromEntries(
    fields.sublist(1).map((e) => MapEntry(
          e.first.toString(),
          ChordProgression(e.sublist(1).map((e) => Chord.parse(e)).toList()),
        )),
  );
}
