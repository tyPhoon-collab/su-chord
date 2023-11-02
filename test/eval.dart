import 'dart:io';

import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/estimator/search.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/note_extractor.dart';
import 'package:chord/service.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:chord/utils/measure.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'util.dart';
import 'writer.dart';

typedef _CorrectChords = Map<_SongID, ChordProgression>;
typedef _SongID = String;
typedef _SoundSource = String;

Future<void> main() async {
  late final Iterable<_EvaluatorContext> contexts;

  setUpAll(() async {
    // CSV書き込みをするなら以下をコメント化
    Table.bypass = true;

    // 計算時間を出力したいなら以下をコメント化
    Measure.logger = null;

    // コード推定結果を出力したいなら以下をコメント化
    _Evaluator.progressionWriter = null;

    // コード推定の正解率を出力したいなら以下をコメント化
    // _Evaluator.correctionWriter = null;

    contexts = await _EvaluatorContext.fromFolder(
      [
        'assets/evals/Halion_CleanGuitarVX',
        // 'assets/evals/Halion_CleanStratGuitar',
        // 'assets/evals/HojoGuitar',
        // 'assets/evals/RealStrat',
      ],
      // songIdsFilter: ['13'],
    );
  });

  test('cross validation', () async {
    Table.bypass = false; //交差検証は目で見てもわからないので、からなず書き込む

    final f = factory2048_1024;
    final db = await f.selector.db;
    final filter = f.filter.eval;

    final folderName = f.context.sanitize();
    final folderPath = 'test/outputs/cross_validations/$folderName';
    final directory = await Directory(folderPath).create(recursive: true);

    debugPrint('${f.context} $folderPath');

    for (final estimator in [
      for (final chromaCalculable in [
        for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
          f.guitarRange.reassignment(scalar: scalar),
          f.guitarRange.combFilter(
            magnitudesCalculable: f.magnitude.stft(scalar: scalar),
          ),
          f.guitarRange.reassignCombFilter(scalar: scalar),
        ]
      ]) ...[
        PatternMatchingChordEstimator(
          chromaCalculable: chromaCalculable,
          filters: filter,
        ),
        SearchTreeChordEstimator(
          chromaCalculable: chromaCalculable,
          filters: filter,
          noteExtractable: switch (chromaCalculable) {
            final HasMagnitudes value =>
              f.extractor.threshold(scalar: value.magnitudeScalar),
            _ => const ThresholdByMaxRatioExtractor(),
          },
          chordSelectable: db,
        ),
      ]
    ]) {
      final fileName = estimator.sanitize();

      debugPrint(estimator.toString());

      final table = _Evaluator(
        header: [estimator.toString()],
        estimator: estimator,
        validator: (progression) => progression.length == 20,
      ).evaluate(contexts);

      table.toCSV('${directory.path}/$fileName.csv');
    }
  });

  group('prop', () {
    final f = factory4096_0;

    test('reassign comb', () async {
      _Evaluator(
        header: ['main'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: f.filter.eval,
        ),
      ).evaluate(contexts).toCSV('test/outputs/main.csv');
    });

    test('ln reassign comb', () async {
      _Evaluator(
        header: ['main'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable:
              f.guitarRange.reassignCombFilter(scalar: MagnitudeScalar.ln),
          filters: f.filter.eval,
        ),
      ).evaluate(contexts).toCSV('test/outputs/main.csv');
    });

    test('main', () async {
      _Evaluator(
        header: ['main'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: f.filter.eval,
        ),
      ).evaluate(contexts).toCSV('test/outputs/main.csv');
    });

    group('template scalar', () {
      test('third scaled', () {
        _Evaluator(
          header: ['scalar'],
          estimator: PatternMatchingChordEstimator(
            chromaCalculable: f.guitarRange.reassignCombFilter(),
            filters: f.filter.eval,
            scalar: const ThirdHarmonicChromaScalar(0.2),
          ),
        ).evaluate(contexts).toCSV('test/outputs/third_scalar.csv');
      });

      test('harmonics scaled', () {
        _Evaluator(
          header: ['scalar'],
          estimator: PatternMatchingChordEstimator(
            chromaCalculable: f.guitarRange.reassignCombFilter(),
            filters: f.filter.eval,
            scalar: HarmonicsChromaScalar(),
          ),
        ).evaluate(contexts).toCSV('test/outputs/harmonics_scalar.csv');
      });
    });

    test('pcp scalar', () {
      _Evaluator(
        header: ['scalar'],
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: f.guitarRange.reassignCombFilter(),
          filters: [
            f.filter.interval(4.seconds),
            const CompressionFilter(),
          ],
        ),
      ).evaluate(contexts).toCSV('test/outputs/pcp_compression.csv');
    });
  });

  group('conv', () {
    final f = factory2048_1024;
    final extractor = f.extractor.threshold();
    final logExtractor = f.extractor.threshold(scalar: MagnitudeScalar.ln);
    test('search + comb', () async {
      _Evaluator(
        header: ['search + comb, $extractor, ${f.context}'],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: f.guitarRange.combFilter(),
          filters: f.filter.eval,
          noteExtractable: extractor,
          chordSelectable: await f.selector.db,
        ),
      ).evaluate(contexts).toCSV('test/outputs/search_tree_comb.csv');
    });

    test('search + log comb', () async {
      _Evaluator(
        header: ['search + log comb, $logExtractor, ${f.context}'],
        estimator: SearchTreeChordEstimator(
          chromaCalculable: f.guitarRange.combFilter(
              magnitudesCalculable:
                  f.magnitude.stft(scalar: MagnitudeScalar.ln)),
          filters: f.filter.eval,
          noteExtractable: logExtractor,
          chordSelectable: await f.selector.db,
        ),
      ).evaluate(contexts).toCSV('test/outputs/search_tree_comb_log.csv');
    });
  });

  group('HCDF', () {
    final f = factory8192_0;

    test('fold', () {
      final e = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter(),
        filters: [f.filter.threshold(20)],
      );

      for (final context in contexts) {
        printProgression('corrects', context.corrects);

        for (final data in context.data.values) {
          final progression = e.estimate(data);
          printProgression('predicts', progression.simplify());
        }

        printSeparation();
      }
    });

    test('cosine similarity', () {
      final e = PatternMatchingChordEstimator(
        chromaCalculable: f.guitarRange.reassignCombFilter(),
        filters: f.filter.cosineSimilarity(similarityThreshold: .85),
      );

      for (final context in contexts) {
        printProgression('corrects', context.corrects);
        for (final data in context.data.values) {
          final progression = e.estimate(data);
          printProgression('predicts', progression.simplify());
        }
        printSeparation();
      }
    });
  });

  //service.dartに登録されている推定器のテスト
  group('riverpods front end estimators', () {
    final estimators = ProviderContainer().read(estimatorsProvider);

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
    int sampleRate = 22050,
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
              (e) => e.loader.load(
                duration: 81,
                sampleRate: sampleRate,
              ),
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
      fields.skip(1).map((e) => MapEntry(
            e.first.toString(),
            ChordProgression(e.skip(1).map((e) => Chord.parse(e)).toList()),
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
    Row? header = const ['no title'],
    this.validator,
  }) : _table = Table.empty(header);

  static Writer? progressionWriter = const DebugPrintWriter();
  static Writer? correctionWriter = const DebugPrintWriter();

  final ChordEstimable estimator;
  final Table _table;
  final bool Function(ChordProgression)? validator;

  Table evaluate(Iterable<_EvaluatorContext> contexts) {
    _table.clear();
    _evaluate(contexts);
    return _table;
  }

  void _evaluate(Iterable<_EvaluatorContext> contexts) {
    final rate = contexts.map(_evaluateOne).sum / contexts.length;
    correctionWriter?.call(
      '${(rate * 100).toStringAsFixed(3)}%',
      title: 'correct rate',
    );
  }

  double _evaluateOne(_EvaluatorContext context) {
    final corrects = context.corrects;
    final progressions = <ChordProgression>[];

    _add(corrects, '${context.songId}_correct');

    context.data.forEach((soundSource, data) {
      final progression = estimator.estimate(data);

      assert(validator?.call(progression) ?? true, 'validation was failed');

      _add(progression, '${context.songId}_$soundSource');
      progressions.add(progression);
    });

    return progressions.map((e) => e.similarity(corrects)).sum /
        context.data.length;
  }

  void _add(ChordProgression progression, String indexLabel) {
    progressionWriter?.call(progression);
    _table.add(progression.toCSVRow()..insert(0, indexLabel));
  }
}
