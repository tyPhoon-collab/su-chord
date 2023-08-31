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
typedef _CorrectChords = Map<_SongID, ChordProgression>;
typedef _SongID = String;
typedef _SoundSource = String;

const sampleRate = 22050;

Future<void> main() async {
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

  final contexts = await _getEvaluatorContexts([
    'assets/evals/Halion_CleanGuitarVX',
    'assets/evals/Halion_CleanStratGuitar',
    'assets/evals/HojoGuitar',
    'assets/evals/RealStrat',
  ]);

  // _Evaluator.bypassCsvWriting = true;

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
      ).evaluate(contexts,
          path: 'test/outputs/pattern_matching_reassignment.csv');
    });
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
      ).evaluate(contexts, path: 'test/outputs/search_tree_comb.csv');
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
      ).evaluate(contexts, path: 'test/outputs/search_tree_comb_db.csv');
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
      ).evaluate(contexts, path: 'test/outputs/pattern_matching_comb.csv');
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
              ))
          .evaluate(contexts,
              path: 'test/outputs/search_tree_reassignment.csv');
    });
  });
}

class _LoaderContext {
  _LoaderContext({required this.path}) {
    final parts = path.split(Platform.pathSeparator); //パスの末尾を取得
    soundSource = parts[parts.length - 2];
    songId = parts.last.split('_').first;
    loader = SimpleAudioLoader(path: path);
  }

  static Iterable<_LoaderContext> fromFolder(String folderPath) {
    return _getFiles(folderPath).map((path) => _LoaderContext(path: path));
  }

  static Iterable<String> _getFiles(String path) {
    final directory = Directory(path);

    if (!directory.existsSync()) {
      throw ArgumentError('Not exists $path');
    }

    final files = directory.listSync();

    return files.whereType<File>().map((e) => e.path);
  }

  final String path;
  late final AudioLoader loader;
  late final _SongID songId;
  late final _SoundSource soundSource;
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
  final Map<_SoundSource, AudioData> data;
  final ChordProgression corrects;

  @override
  int compareTo(_EvaluatorContext other) {
    return key.compareTo(other.key);
  }
}

//描画するライブラリが乏しいため、全体的な統計や評価はExcelで行う
//そのために必要なデータの書き出しや、基本的な統計量を提示する
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

    _initTable(path);
    _evaluate(context);

    if (path != null) table?.toCSV(path);
  }

  void _initTable(String? path) {
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
  }

  void _evaluate(Iterable<_EvaluatorContext> contexts) {
    final correctRate = contexts.map(_evaluateOne).sum / contexts.length;
    debugPrint('corrects: ${(correctRate * 100).toStringAsFixed(3)}%');
  }

  double _evaluateOne(_EvaluatorContext context) {
    final corrects = context.corrects;
    final progressions = <ChordProgression>[];

    _add(corrects, '${context.songId}_correct');

    context.data.forEach((soundSource, data) {
      final progression = estimator.estimate(data);
      _add(progression, '${context.songId}_$soundSource');
      progressions.add(progression);
    });

    return progressions.map((e) => e.consistencyRate(corrects)).sum /
        context.data.length;
  }

  void _add(ChordProgression progression, String indexLabel) {
    debugPrint(progression.toString());
    table?.add(progression.toCSVRow()..insert(0, indexLabel));
  }
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

Future<Iterable<_EvaluatorContext>> _getEvaluatorContexts(
    Iterable<String> folderPaths) async {
  final contexts = <_EvaluatorContext>[];
  final corrects = await _getCorrectChords();
  final loaders =
      folderPaths.map((e) => _LoaderContext.fromFolder(e)).flattened;

  final loadersMap = loaders.groupListsBy((e) => e.songId);
  for (final entry in loadersMap.entries) {
    final songId = entry.key;
    final loaderContexts = entry.value;
    contexts.add(
      _EvaluatorContext(
        key: int.parse(songId),
        songId: songId,
        data: Map.fromIterables(
          loaderContexts.map((e) => e.soundSource),
          await Future.wait(loaderContexts.map(
            (e) => e.loader.load(duration: 83, sampleRate: sampleRate),
          )),
        ),
        corrects: corrects[songId]!,
      ),
    );
  }

  contexts.sort((a, b) => a.compareTo(b));
  return contexts;
}
