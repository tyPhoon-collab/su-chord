import 'dart:io';

import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/score.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';

import '../data_set.dart';
import '../writer.dart';

class EvaluationAudioDataContext
    implements Comparable<EvaluationAudioDataContext> {
  EvaluationAudioDataContext({
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
    final musicName = parts.last.split('_').first; //現状ではただの数字
    final timeAnnotationPath =
        'assets/csv/correct_time_annotation_$soundSourceName.csv';
    final key = int.parse(musicName);

    final data = await audioLoader.load(audioPath, duration: 81);

    final corrects = await csvLoader.load('assets/csv/correct_only_sharp.csv');
    final timeAnnotation = await csvLoader.load(timeAnnotationPath);
    final times = timeAnnotation
        .skip(1)
        .map((e) => Time.fromList(
            e.skip(1).map((e) => double.parse(e.toString())).toList()))
        .toList();

    final correct = ChordProgression.fromChordRow(
      corrects[key].skip(1).map((e) => e.toString()).toList(),
      times: times,
    );

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
}

//描画するライブラリが乏しいため、全体的な統計や評価はExcelで行う
//そのために必要なデータの書き出しや、基本的な統計量を提示する
class Evaluator {
  Evaluator({
    required this.estimator,
    Header header = const ['no title'],
    this.validator,
  }) : _table = Table.empty(header);

  static LogTest? progressionWriter = logTest;
  static LogTest? correctionWriter = logTest;

  final ChordEstimable estimator;
  final Table _table;
  final bool Function(ChordProgression)? validator;

  Table evaluate(Iterable<EvaluationAudioDataContext> contexts) {
    _table.clear();

    final groupedContexts = groupBy(contexts, (p0) => p0.musicName);

    double rate = 0;

    for (final entry in groupedContexts.entries) {
      final correct = entry.value.first.correct;
      _add(correct, '${entry.key}_correct');

      for (final context in entry.value) {
        final progression = estimator.estimate(context.data);

        assert(validator?.call(progression) ?? true, 'validation was failed');

        _add(progression, '${entry.key}_${context.soundSourceName}');
        rate += progression.similarity(correct);
      }
    }
    correctionWriter?.call(
      '${((rate / contexts.length) * 100).toStringAsFixed(3)}%',
      title: 'correct rate',
    );

    return _table;
  }

  void _add(ChordProgression progression, String indexLabel) {
    progressionWriter?.call(progression);
    _table.add(progression.toCSVRow()..insert(0, indexLabel));
  }
}

//描画するライブラリが乏しいため、全体的な統計や評価はExcelで行う
//そのために必要なデータの書き出しや、基本的な統計量を提示する
class HCDFEvaluator {
  HCDFEvaluator({
    required this.estimator,
  });

  static LogTest? progressionWriter = logTest;
  static LogTest? correctionWriter = logTest;

  final ChordEstimable estimator;

  void evaluate(Iterable<EvaluationAudioDataContext> contexts) {
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

      rate += correct.overlapScore(predict);
    }

    correctionWriter?.call(
      (rate / contexts.length).toStringAxFixed(3),
      title: 'correct rate',
    );
  }
}
