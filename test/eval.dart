import 'dart:io';

import 'package:chord/config.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma_calculators/magnitudes_calculator.dart';
import 'package:chord/domains/estimator.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/service.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:chord/utils/measure.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

typedef _CorrectChords = Map<_SongID, ChordProgression>;
typedef _SongID = String;
typedef _SoundSource = String;

Future<void> main() async {
  final contexts = await _getEvaluatorContexts(
    [
      'assets/evals/Halion_CleanGuitarVX',
      // 'assets/evals/Halion_CleanStratGuitar',
      // 'assets/evals/HojoGuitar',
      // 'assets/evals/RealStrat',
    ],
    // songIds: ['13'],
  );

  _Evaluator.bypassCsvWriting = true;
  Measure.logger = null;

  test('cross validation', () {
    //TODO impl this
    //以下の場合をすべて確かめて、csvに出力する

    //パターンマッチング
    //探索木

    //スパース + 平均律ビン
    //スパース + コムフィルタ
    //コムフィルタ

    //L2ノルム
    //自然対数
    //(dB)

    //DB
    //DBなし

    // final f = factory8192_0;
  });

  group('prop', () {
    test('main', () async {
      _Evaluator(
        header: ['matching + reassignment + db, ${factory2048_1024.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory2048_1024.guitarRange.reassignment,
          filters: factory2048_1024.filter.eval,
          chordSelectable: await factory2048_1024.selector.db,
        ),
      ).evaluate(contexts,
          path: 'test/outputs/pattern_matching_reassignment_db.csv');
    });

    test('sub', () async {
      _Evaluator(
        header: ['matching + reassignment, ${factory2048_1024.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory2048_1024.guitarRange.reassignment,
          filters: factory2048_1024.filter.eval,
        ),
      ).evaluate(contexts,
          path: 'test/outputs/pattern_matching_reassignment.csv');
    });

    group('template scalar', () {
      test('thirdHarmonic', () async {
        const factor = 0.2;

        _Evaluator(
          header: [
            'matching + reassignment + db + scalar, ${factory2048_1024.context}'
          ],
          estimator: PatternMatchingChordEstimator(
            chromaCalculable: factory2048_1024.guitarRange.reassignment,
            filters: factory2048_1024.filter.eval,
            chordSelectable: await factory2048_1024.selector.db,
            scalar: TemplateChromaScalar.thirdHarmonic(factor),
          ),
        ).evaluate(contexts,
            path: 'test/outputs/pattern_matching_reassignment_db_scalar.csv');
      });
    });
  });

  group('conv', () {
    test('search + comb', () async {
      const ratio = 0.3;

      _Evaluator(
        header: ['search + comb, ratio: $ratio, ${factory8192_0.context}'],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
        ),
      ).evaluate(contexts, path: 'test/outputs/search_tree_comb.csv');
    });

    test('search + log comb', () async {
      const ratio = 0.5;

      _Evaluator(
        header: ['search + log comb, ratio: $ratio, ${factory8192_0.context}'],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilterWith(
              magnitudesCalculable:
                  factory8192_0.magnitude.stft(scalar: MagnitudeScalar.ln)),
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
        ),
      ).evaluate(contexts, path: 'test/outputs/search_tree_comb_log.csv');
    });

    test('search + comb + db', () async {
      const ratio = 0.3;

      _Evaluator(
        header: ['search + comb + db, ratio: $ratio, ${factory8192_0.context}'],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
          chordSelectable: await factory8192_0.selector.db,
        ),
      ).evaluate(contexts, path: 'test/outputs/search_tree_comb_db.csv');
    });

    test('search + log comb + db', () async {
      const ratio = 0.5;

      _Evaluator(
        header: [
          'search + log comb + db, ratio: $ratio, ${factory8192_0.context}'
        ],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilterWith(
              magnitudesCalculable:
                  factory8192_0.magnitude.stft(scalar: MagnitudeScalar.ln)),
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
          chordSelectable: await factory8192_0.selector.db,
        ),
      ).evaluate(contexts, path: 'test/outputs/search_tree_comb_log_db.csv');
    });
  });

  group('control experiment', () {
    test('matching + comb filter', () {
      _Evaluator(
        header: ['matching + comb filter, ${factory8192_0.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
        ),
      ).evaluate(contexts, path: 'test/outputs/pattern_matching_comb.csv');
    });

    test('matching + comb filter + scalar', () async {
      _Evaluator(
        header: ['matching + comb filter, ${factory8192_0.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilter,
          filters: factory8192_0.filter.eval,
          chordSelectable: await factory8192_0.selector.db,
          scalar: TemplateChromaScalar.thirdHarmonic(0.1),
        ),
      ).evaluate(contexts,
          path: 'test/outputs/pattern_matching_comb_scalar.csv');
    });

    test('matching + log comb filter', () {
      _Evaluator(
        header: ['matching + log comb filter, ${factory8192_0.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.combFilterWith(
              magnitudesCalculable:
                  factory8192_0.magnitude.stft(scalar: MagnitudeScalar.ln)),
          filters: factory8192_0.filter.eval,
        ),
      ).evaluate(contexts, path: 'test/outputs/pattern_matching_comb_log.csv');
    });

    test('search + reassignment', () {
      const ratio = 0.5;
      _Evaluator(
        header: [
          'search + reassignment, ratio: $ratio, ${factory8192_0.context}'
        ],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: factory8192_0.guitarRange.reassignment,
          filters: factory8192_0.filter.eval,
          thresholdRatio: ratio,
        ),
      ).evaluate(contexts, path: 'test/outputs/search_tree_reassignment.csv');
    });
  });

  //service.dartに登録されている推定器のテスト
  group('riverpods front end estimators', () {
    final container = ProviderContainer();
    final estimators = container.read(estimatorsProvider);

    test('all', () async {
      for (final MapEntry(:key, :value) in estimators.entries) {
        final estimator = await value();
        _Evaluator(
          header: [key],
          estimator: estimator,
        ).evaluate(contexts, path: 'test/outputs/front_ends/$key.csv');
      }
    });

    test('one', () async {
      const id = 'main'; // change here

      final estimator = await estimators[id]!.call();
      _Evaluator(
        header: [id],
        estimator: estimator,
      ).evaluate(contexts, path: 'test/outputs/front_ends/$id.csv');
    });
  });
}

class _LoaderContext {
  _LoaderContext({required this.path}) {
    final parts = path.split(Platform.pathSeparator); //パスを分解
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

///評価する際の必要な情報を詰め込んだクラス
///正解ラベルに対して、音源識別子と音源がkey-valueになったMapを持つ
///そのため、正解ラベルと音源は1対多の関係とする
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

  void evaluate(Iterable<_EvaluatorContext> contexts, {String? path}) {
    assert(path == null || path.endsWith('.csv'));

    _initTable(path);
    _evaluate(contexts);

    if (path != null) table?.toCSV(path);
  }

  void _initTable(String? path) {
    if (path == null) return;

    if (!bypassCsvWriting) {
      table = Table.empty(header);
    } else {
      debugPrint('CSV writing is bypassing');
    }
  }

  void _evaluate(Iterable<_EvaluatorContext> contexts) {
    final correctRate = contexts.map(_evaluateOne).sum / contexts.length;
    debugPrint('correct rate: ${(correctRate * 100).toStringAsFixed(3)}%');
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
    Iterable<String> folderPaths,
    {Iterable<_SongID>? songIds}) async {
  final contexts = <_EvaluatorContext>[];
  final corrects = await _getCorrectChords();
  final loaders =
      folderPaths.map((e) => _LoaderContext.fromFolder(e)).flattened;

  final loadersMap = loaders
      .where((e) => songIds?.contains(e.songId) ?? true)
      .groupListsBy((e) => e.songId);
  for (final MapEntry(key: songId, :value) in loadersMap.entries) {
    contexts.add(
      _EvaluatorContext(
        key: int.parse(songId),
        songId: songId,
        data: Map.fromIterables(
          value.map((e) => e.soundSource),
          await Future.wait(value.map(
            (e) => e.loader.load(duration: 83, sampleRate: Config.sampleRate),
          )),
        ),
        corrects: corrects[songId]!,
      ),
    );
  }

  contexts.sort((a, b) => a.compareTo(b));
  return contexts;
}
