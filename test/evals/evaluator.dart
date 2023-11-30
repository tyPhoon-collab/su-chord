import 'dart:io';

import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/score.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../data_set.dart';
import '../writer.dart';

abstract class EvaluationAudioDataContextDelegate {
  int key(List<String> parts);

  String soundSourceName(List<String> parts);

  String musicName(List<String> parts);

  String annotationPath(List<String> parts);
}

final class KonokiEADCDelegate implements EvaluationAudioDataContextDelegate {
  const KonokiEADCDelegate();

  @override
  int key(List<String> parts) {
    final musicIndex = parts.last
        .split('_')
        .first;

    return int.parse(musicIndex);
  }

  @override
  String annotationPath(List<String> parts) =>
      'assets/csv/${soundSourceName(parts)}/${musicName(parts)}.csv';

  @override
  String musicName(List<String> parts) =>
      parts.last.substring(0, parts.last.indexOf('.'));

  @override
  String soundSourceName(List<String> parts) => parts[parts.length - 2];
}

final class GuitarSetEADCDelegate
    implements EvaluationAudioDataContextDelegate {
  const GuitarSetEADCDelegate();

  @override
  String annotationPath(List<String> parts) =>
      'assets/csv/${soundSourceName(parts)}/${musicName(parts)}.csv';

  @override
  int key(List<String> parts) {
    final fileName = parts.last;
    final numberString = fileName
        .split('_')
        .first[1];
    final kindString = fileName
        .split('-')
        .first;
    final orderString = kindString[kindString.length - 1];

    return int.parse(numberString) * 10 + int.parse(orderString);
  }

  @override
  String musicName(List<String> parts) =>
      parts.last.substring(0, parts.last.indexOf('.'));

  @override
  String soundSourceName(List<String> parts) => parts[parts.length - 2];
}

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

  static Future<EvaluationAudioDataContext> fromFile(String audioPath,
      EvaluationAudioDataContextDelegate delegate,) async {
    final parts = audioPath.split(Platform.pathSeparator);

    final data = await audioLoader.load(audioPath);
    final annotation = await csvLoader.load(delegate.annotationPath(parts));

    final corrects = <String>[];
    final times = <Time>[];

    for (final value in annotation.skip(1)) {
      corrects.add(value[0]);
      times.add(Time(value[1], value[2]));
    }

    final correct = ChordProgression.fromChordRow(corrects, times: times);

    return EvaluationAudioDataContext(
      key: delegate.key(parts),
      data: data,
      correct: correct,
      soundSourceName: delegate.soundSourceName(parts),
      musicName: delegate.musicName(parts),
    );
  }

  static Future<List<EvaluationAudioDataContext>> fromFolder(String folderPath,
      EvaluationAudioDataContextDelegate delegate, {
        bool Function(String path)? filter,
      }) async {
    return Future.wait(
      _getFiles(folderPath)
          .where((e) => filter?.call(e) ?? true)
          .map((path) => EvaluationAudioDataContext.fromFile(path, delegate)),
    ).then((value) => value.sorted((a, b) => a.compareTo(b)));
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

  Table evaluate(Iterable<EvaluationAudioDataContext> contexts, {
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

  void _add(Table table,
      ChordProgression<Chord> progression,
      String indexLabel,) {
    progressionWriter?.call(progression);
    table.add(progression.toRow()
      ..insert(0, indexLabel));
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

  Table evaluate(Iterable<EvaluationAudioDataContext> contexts, {
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
    table.add(score.toRow()
      ..insert(0, indexLabel));
  }
}

class HCDFVisualizer {
  const HCDFVisualizer({required this.estimator});

  final ChordEstimable estimator;

  Future<void> visualize(EvaluationAudioDataContext context, {
    String? title,
    EstimatorFactoryContext? factoryContext,
  }) async {
    final correct = context.correct;
    final predict = estimator.estimate(context.data, false);

    if (factoryContext != null) {
      if (estimator case final HasChromaList haver) {
        await HCDFDetailChartWriter(
          sampleRate: factoryContext.sampleRate,
          chunkSize: factoryContext.chunkSize,
          chunkStride: factoryContext.chunkStride,
        ).call(
          correct.simplify(),
          predict.simplify(),
          haver.chromas(),
          title: title,
        );
      } else {
        throw ArgumentError('estimator does not implements HasChromaList');
      }
    } else {
      await const HCDFChartWriter().call(
        correct.simplify(),
        predict.simplify(),
        title: title,
      );
    }

    estimator.flush();
  }
}
