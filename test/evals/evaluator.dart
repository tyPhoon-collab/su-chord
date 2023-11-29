import 'dart:io';

import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/score.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../data_set.dart';
import '../writer.dart';

///評価音源に必要な情報をすべて詰め込んだクラス
@immutable
final class EvaluationAudioDataContext
    implements Comparable<EvaluationAudioDataContext> {
  const EvaluationAudioDataContext({
    required this.key,
    required this.data,
    required this.correct,
    required this.soundSourceName,
    required this.musicName,
  });

  static final audioLoader = CacheableAudioLoader(sampleRate: 22050);
  static final csvLoader = CacheableCSVLoader();

  static Future<EvaluationAudioDataContext> fromFile(String audioPath) async {
    final parts = audioPath.split(Platform.pathSeparator); //パスを分解
    final soundSourceName = parts[parts.length - 2]; //フォルダに音源名があると仮定する
    final fileName = parts.last.substring(0, parts.last.indexOf('.'));
    final musicName = fileName.split('_').first; //現状ではただの数字

    //音声ファイルと全く同じファイル名のアノテーションファイルがassets/csvにあるとする
    final annotationPath = 'assets/csv/$soundSourceName/$fileName.csv';

    final key = int.parse(musicName);

    final data = await audioLoader.load(audioPath);
    final annotation = await csvLoader.load(annotationPath);

    final corrects = annotation.skip(1).map((e) => e[0].toString()).toList();
    final times = annotation
        .skip(1)
        .map((e) => Time.fromList(
            e.skip(1).map((e) => double.parse(e.toString()) / 1000).toList()))
        .toList();

    final correct = ChordProgression.fromChordRow(corrects, times: times);

    return EvaluationAudioDataContext(
      key: key,
      data: data,
      correct: correct,
      soundSourceName: soundSourceName,
      musicName: musicName,
    );
  }

  static Future<List<EvaluationAudioDataContext>> fromFolder(
      String folderPath) async {
    final s = Stopwatch()..start();
    final contexts = Future.wait(_getFiles(folderPath)
            .map((path) => EvaluationAudioDataContext.fromFile(path)))
        .then((value) => value.sorted((a, b) => a.compareTo(b)));
    s.stop();
    logTest(
      '$folderPath load took ${s.elapsedMilliseconds}ms',
      title: 'measure',
    );
    return contexts;
  }

  static Iterable<String> _getFiles(String path) {
    final directory = Directory(path);

    if (!directory.existsSync()) {
      throw ArgumentError('Not exists $path');
    }

    final files = directory.listSync();

    return files.whereType<File>().map((e) => e.path);
  }

  final int key;
  final AudioData data;
  final ChordProgression<Chord> correct;
  final String soundSourceName;
  final String musicName;

  @override
  int compareTo(EvaluationAudioDataContext other) {
    return key.compareTo(other.key);
  }

  EvaluationAudioDataContext copyWith({
    int? key,
    AudioData? data,
    ChordProgression<Chord>? correct,
    String? soundSourceName,
    String? musicName,
  }) {
    return EvaluationAudioDataContext(
      key: key ?? this.key,
      data: data ?? this.data,
      correct: correct ?? this.correct,
      soundSourceName: soundSourceName ?? this.soundSourceName,
      musicName: musicName ?? this.musicName,
    );
  }
}

//描画するライブラリが乏しいため、全体的な統計や評価はExcelで行う
//そのために必要なデータの書き出しや、基本的な統計量を提示する
class Evaluator {
  const Evaluator({
    required this.estimator,
    this.validator,
  });

  static LogTest? progressionWriter = logTest;
  static LogTest? correctionWriter = logTest;

  final ChordEstimable estimator;
  final bool Function(ChordProgression)? validator;

  Table evaluate(
    Iterable<EvaluationAudioDataContext> contexts, {
    String header = 'no title',
  }) {
    final table = Table.empty([header]);

    final groupedContexts = groupBy(contexts, (p0) => p0.musicName);

    double rate = 0;

    for (final entry in groupedContexts.entries) {
      final correct = entry.value.first.correct;
      _add(table, correct, '${entry.key}_correct');

      for (final context in entry.value) {
        final progression = estimator.estimate(context.data);

        assert(validator?.call(progression) ?? true, 'validation was failed');

        _add(table, progression, '${entry.key}_${context.soundSourceName}');
        rate += progression.similarity(correct);
      }
    }
    correctionWriter?.call(
      '${((rate / contexts.length) * 100).toStringAsFixed(3)}%',
      title: 'CORRECT RATE',
    );

    return table;
  }

  void _add(
    Table table,
    ChordProgression<Chord> progression,
    String indexLabel,
  ) {
    progressionWriter?.call(progression);
    table.add(progression.toRow()..insert(0, indexLabel));
  }
}

//描画するライブラリが乏しいため、全体的な統計や評価はExcelで行う
//そのために必要なデータの書き出しや、基本的な統計量を提示する
class HCDFEvaluator {
  const HCDFEvaluator({
    required this.estimator,
  });

  static LogTest? progressionWriter = logTest;
  static LogTest? correctionWriter = logTest;

  final ChordEstimable estimator;

  Table evaluate(
    Iterable<EvaluationAudioDataContext> contexts, {
    String header = 'no title',
  }) {
    final table = Table.empty([header, ...FScore.csvHeader]);

    FScore rate = FScore.zero;
    for (final context in contexts) {
      final correct = context.correct;
      final predict = estimator.estimate(context.data);

      progressionWriter?.call(
        correct.simplify().toDetailString(),
        title: 'correct',
      );
      progressionWriter?.call(
        predict.simplify().toDetailString(),
        title: 'predict',
      );

      final score = correct.overlapScore(predict);
      _add(table, score, context.musicName);
      rate += score;
    }

    correctionWriter?.call(
      (rate / contexts.length).toStringAxFixed(3),
      title: 'correct rate',
    );

    return table;
  }

  void _add(Table table, FScore score, String indexLabel) {
    table.add(score.toRow()..insert(0, indexLabel));
  }
}

class HCDFVisualizer {
  const HCDFVisualizer({required this.estimator});

  final ChordEstimable estimator;

  Future<void> visualize(
    EvaluationAudioDataContext context, {
    String? title,
  }) async {
    final correct = context.correct;
    final predict = estimator.estimate(context.data);

    await const HCDFChartWriter().call(
      correct.simplify(),
      predict.simplify(),
      title: title,
    );
  }
}
