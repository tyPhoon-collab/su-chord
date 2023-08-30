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
  // _Evaluator.bypassCsvWriting = true;

  final corrects = await _getCorrectChords();
  final loaders = Map.fromEntries([
    ...await _getFiles('assets/evals/Halion_CleanGuitarVX')
        .then((files) => files.map(_parsePathToMapEntries)),
    // ...await _getFiles('assets/evals/Halion_CleanStratGuitar')
    //     .then((files) => files.map(_parsePathToMapEntries)),
    // ...await _getFiles('assets/evals/HojoGuitar')
    //     .then((files) => files.map(_parsePathToMapEntries)),
    // ...await _getFiles('assets/evals/RealStrat')
    //     .then((files) => files.map(_parsePathToMapEntries)),
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
        header: [
          'pattern matching + reassignment, ${factory2048_1024.context}'
        ],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory2048_1024.guitarRange.reassignment,
          filters: factory2048_1024.filter.eval,
        ),
      ).evaluate(data, path: 'test/outputs/pattern_matching_reassignment.csv');
    });

    // test('prop to conv chunkSize', () async {
    //   _Evaluator(
    //     estimator: PatternMatchingChordEstimator(
    //       chromaCalculable: factory8192_0.guitarRange.reassignment,
    //       filters: factory8192_0.filter.eval,
    //     ),
    //   ).evaluate(data, path: 'test/outputs/prop.csv');
    // });

    // test('piano tuning', () async {
    //   _Evaluator(
    //     estimator: PatternMatchingChordEstimator(
    //       chromaCalculable: factory2048_1024.bigRange.reassignment,
    //       filters: factory2048_1024.filter.eval,
    //     ),
    //   ).evaluate(data);
    // });
  });

  group('conv', () {
    test('search tree + comb', () async {
      const ratio = 0.3;

      _Evaluator(
        header: ['search tree + comb, ratio: $ratio, ${factory8192_0.context}'],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
        ),
      ).evaluate(data, path: 'test/outputs/search_tree_comb.csv');
    });

    test('search tree + comb + db', () async {
      final csv = await CSVLoader.db.load();
      const ratio = 0.3;

      _Evaluator(
        header: [
          'search tree + comb + db, ratio: $ratio, ${factory8192_0.context}'
        ],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
          chordSelectable: ChordProgressionDBChordSelector.fromCSV(csv),
        ),
      ).evaluate(data, path: 'test/outputs/search_tree_comb_db.csv');
    });
  });

  group('control experiment', () {
    test('pattern matching + comb filter', () {
      _Evaluator(
        header: ['pattern matching + comb filter, ${factory8192_0.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
        ),
      ).evaluate(data, path: 'test/outputs/pattern_matching_comb.csv');
    });

    test('search tree + reassignment', () {
      const ratio = 0.5;
      _Evaluator(
          header: [
            'search tree + reassignment, ratio: $ratio, ${factory8192_0.context}'
          ],
          estimator: SearchTreeChordEstimator(
            chromaCalculable: factory8192_0.guitarRange.reassignment,
            filters: factory8192_0.filter.eval,
            thresholdRatio: ratio,
          )).evaluate(data, path: 'test/outputs/search_tree_reassignment.csv');
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
  _Evaluator({
    required this.estimator,
    this.header,
  });

  static bool bypassCsvWriting = false;

  final List<String>? header;
  final ChordEstimable estimator;
  Table? table;

  void evaluate(Iterable<_EvaluatorContext> context, {String? path}) {
    assert(path == null || path.endsWith('.csv'));
    if (path != null) {
      if (!bypassCsvWriting) {
        table = Table.empty();
        if (header != null) {
          table!.add(header!);
        }
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
