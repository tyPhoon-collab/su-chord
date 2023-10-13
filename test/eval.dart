import 'dart:io';

import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/estimator.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
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
  final contexts = await _EvaluatorContext.fromFolder(
    [
      'assets/evals/Halion_CleanGuitarVX',
      // 'assets/evals/Halion_CleanStratGuitar',
      // 'assets/evals/HojoGuitar',
      // 'assets/evals/RealStrat',
    ],
    // songIdsFilter: ['13'],
  );

  Table.bypass = true;
  Measure.logger = null;

  test('cross validation', () {
    //TODO 見やすく書けるようにする

    //以下の場合をすべて確かめて、csvに出力する

    //* ChordEstimator
    //パターンマッチング
    //探索木

    //* ChromaCalculator
    //スパース + 平均律ビン
    //スパース + コムフィルタ
    //コムフィルタ

    //* MagnitudeScalar
    //L2ノルム
    //自然対数
    //(dB)

    final f = factory8192_0;

    for (final estimator in [
      for (final chromaCalculable in [
        for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
          f.guitarRange.reassignmentWith(scalar: scalar),
          f.guitarRange.combFilterWith(
            combFilterContext: const CombFilterContext(),
            magnitudesCalculable: f.magnitude.stft(scalar: scalar),
          ),
          f.guitarRange.combFilterWith(
            combFilterContext: const CombFilterContext(),
            magnitudesCalculable: f.magnitude.reassignment(scalar: scalar),
          ),
        ]
      ]) ...[
        PatternMatchingChordEstimator(
          chromaCalculable: chromaCalculable,
          filters: f.filter.eval,
        ),
        SearchTreeChordEstimator(
            chromaCalculable: chromaCalculable,
            filters: f.filter.eval,
            thresholdRatio: switch (chromaCalculable) {
              final HasMagnitudes value => switch (value.magnitudeScalar) {
                  MagnitudeScalar.none => 0.3,
                  MagnitudeScalar.ln => 0.5,
                  MagnitudeScalar.dB => 0.5,
                },
              _ => 0.65,
            }),
      ]
    ]) {
      final fileName = estimator
          .toString()
          .replaceAll(RegExp(r'\s+'), '_')
          .replaceAll(',', '__');

      debugPrint(estimator.toString());

      final table = _Evaluator(
        header: [estimator.toString()],
        estimator: estimator,
      ).evaluate(contexts);

      table.toCSV('test/outputs/cross_validations/$fileName.csv');

      for (final row in table.headlessValues) {
        debugPrint(ChordProgression.fromCSVRow(
          row.sublist(1),
          ignoreNotParsable: true,
        ).toString());
      }
    }
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
      )
          .evaluate(contexts)
          .toCSV('test/outputs/pattern_matching_reassignment_db.csv');
    });

    test('sub', () async {
      _Evaluator(
        header: ['matching + reassignment, ${factory2048_1024.context}'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: factory2048_1024.guitarRange.reassignment,
          filters: factory2048_1024.filter.eval,
        ),
      )
          .evaluate(contexts)
          .toCSV('test/outputs/pattern_matching_reassignment.csv');
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
        )
            .evaluate(contexts)
            .toCSV('test/outputs/pattern_matching_reassignment_db_scalar.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/search_tree_comb.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/search_tree_comb_log.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/search_tree_comb_db.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/search_tree_comb_log_db.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/pattern_matching_comb.csv');
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
      )
          .evaluate(contexts)
          .toCSV('test/outputs/pattern_matching_comb_scalar.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/pattern_matching_comb_log.csv');
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
      ).evaluate(contexts).toCSV('test/outputs/search_tree_reassignment.csv');
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
        ).evaluate(contexts).toCSV('test/outputs/front_ends/$key.csv');
      }
    });

    test('one', () async {
      const id = 'main'; // change here

      final estimator = await estimators[id]!.call();
      _Evaluator(
        header: [id],
        estimator: estimator,
      ).evaluate(contexts).toCSV('test/outputs/front_ends/$id.csv');
    });
  });
}

class _LoaderContext {
  const _LoaderContext({
    required this.path,
    required this.loader,
    required this.songId,
    required this.soundSource,
  });

  factory _LoaderContext.fromFile(String path) {
    final parts = path.split(Platform.pathSeparator); //パスを分解
    final soundSource = parts[parts.length - 2];
    final songId = parts.last.split('_').first;
    final loader = SimpleAudioLoader(path: path);

    return _LoaderContext(
      path: path,
      loader: loader,
      songId: songId,
      soundSource: soundSource,
    );
  }

  static Iterable<_LoaderContext> fromFolder(String folderPath) =>
      _getFiles(folderPath).map((path) => _LoaderContext.fromFile(path));

  static Iterable<String> _getFiles(String path) {
    final directory = Directory(path);

    if (!directory.existsSync()) {
      throw ArgumentError('Not exists $path');
    }

    final files = directory.listSync();

    return files.whereType<File>().map((e) => e.path);
  }

  final String path;
  final AudioLoader loader;
  final _SongID songId;
  final _SoundSource soundSource;
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

  static Future<Iterable<_EvaluatorContext>> fromFolder(
    Iterable<String> folderPaths, {
    Iterable<_SongID>? songIdsFilter,
  }) async {
    final contexts = <_EvaluatorContext>[];
    final corrects = await _getCorrectChords();
    final loaders =
        folderPaths.map((e) => _LoaderContext.fromFolder(e)).flattened;

    final loadersMap = loaders
        .where((e) => songIdsFilter?.contains(e.songId) ?? true)
        .groupListsBy((e) => e.songId);
    for (final MapEntry(key: songId, :value) in loadersMap.entries) {
      contexts.add(
        _EvaluatorContext(
          key: int.parse(songId),
          songId: songId,
          data: Map.fromIterables(
            value.map((e) => e.soundSource),
            await Future.wait(value.map(
              (e) => e.loader.load(duration: 83, sampleRate: 22050),
            )),
          ),
          corrects: corrects[songId]!,
        ),
      );
    }

    contexts.sort((a, b) => a.compareTo(b));
    return contexts;
  }

  static Future<_CorrectChords> _getCorrectChords() async {
    final fields = await CSVLoader.corrects.load();

    //ignore header
    return Map.fromEntries(
      fields.sublist(1).map((e) => MapEntry(
            e.first.toString(),
            ChordProgression(e.sublist(1).map((e) => Chord.parse(e)).toList()),
          )),
    );
  }

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
    Row? header,
  }) : _table = Table.empty(header);

  final ChordEstimable estimator;
  final Table _table;

  Table evaluate(Iterable<_EvaluatorContext> contexts) {
    _table.clear();
    _evaluate(contexts);
    return _table;
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
    _table.add(progression.toCSVRow()..insert(0, indexLabel));
  }
}
