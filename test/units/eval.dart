import 'dart:convert';
import 'dart:io';

import 'package:chord/config.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimate.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/loader.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

//Song ID : ChordProgression
typedef _CorrectChords = Map<String, ChordProgression>;
typedef _SongID = String;
typedef _Paths = Iterable<String>;

@immutable
class EvaluatorContext {
  const EvaluatorContext({required this.data, required this.corrects});

  final AudioData data;
  final ChordProgression corrects;
}

class Evaluator {
  Evaluator({required this.estimator});

  final ChordEstimable estimator;

  void evaluate(Iterable<EvaluatorContext> context) {
    final sum = context.map(_evaluate).sum;
    final correctRate = sum / context.length * 100;
    debugPrint('corrects: ${correctRate.toStringAsFixed(3)}%');
  }

  double _evaluate(EvaluatorContext context) {
    final data = context.data;
    final corrects = context.corrects;
    final chords = estimator.estimate(data);

    debugPrint(chords.toString());
    debugPrint(corrects.toString());

    return chords.consistencyRate(corrects);
  }
}

Future<void> main() async {
  const sampleRate = Config.sampleRate;

  final corrects = await _getCorrectChords();
  final Map<_SongID, AudioLoader> loaders = Map.fromEntries([
    ...await _getFiles('assets/evals/Halion_CleanGuitarVX')
        .then((files) => files.map(_parsePathToMapEntries)),
  ]);
  final data = <EvaluatorContext>[];

  setUpAll(() async {
    for (final entry in loaders.entries) {
      data.add(EvaluatorContext(
        data: await entry.value.load(duration: 84, sampleRate: sampleRate),
        corrects: corrects[entry.key]!,
      ));
    }
  });

  group('prop', () {
    test('best', () async {
      Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: ReassignmentChromaCalculator(),
          filters: [
            // ThresholdFilter(threshold: 100),
            IntervalChordChangeDetector(
              interval: 4,
              dt: Config.chunkStride / Config.sampleRate,
            ),
          ],
        ),
      ).evaluate(data);
    });
  });

  group('conv', () {
    test('comb + search tree', () async {
      const chunkSize = 8192;
      const chunkStride = 0;
      const dt = chunkSize / sampleRate;
      Evaluator(
        estimator: SearchTreeChordEstimator(
          chromaCalculable: CombFilterChromaCalculator(
            chunkSize: chunkSize,
            chunkStride: chunkStride,
            lowest: MusicalScale.E2,
            perOctave: 6,
          ),
          filters: [
            // ThresholdFilter(threshold: 1),
            IntervalChordChangeDetector(interval: 4, dt: dt),
          ],
          thresholdRatio: 0.25,
        ),
      ).evaluate(data);
    });
  });

  test('eval pattern matching with comb filter', () async {
    Evaluator(
        estimator: PatternMatchingChordEstimator(
      chromaCalculable: CombFilterChromaCalculator(),
      filters: [
        IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      ],
    )).evaluate(data);
  });

  test('eval search tree with reassignment', () async {
    Evaluator(
        estimator: SearchTreeChordEstimator(
      chromaCalculable: ReassignmentChromaCalculator(),
      filters: [
        IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      ],
    )).evaluate(data);
  });

  test('eval conv lowest C1, octave 7', () async {
    Evaluator(
        estimator: SearchTreeChordEstimator(
      chromaCalculable: CombFilterChromaCalculator(),
      filters: [
        IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      ],
    )).evaluate(data);
  });

  test('eval conv threshold changed', () async {
    Evaluator(
        estimator: SearchTreeChordEstimator(
      chromaCalculable: CombFilterChromaCalculator(),
      filters: [
        IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      ],
      thresholdRatio: 0.3,
    )).evaluate(data);
  });
}

Future<_Paths> _getFiles(String path) async {
  final directory = Directory(path);

  if (!directory.existsSync()) {
    throw ArgumentError('Not exists $path');
  }

  final files = directory.listSync();

  return files.whereType<File>().map((e) => e.path);
}

MapEntry<_SongID, AudioLoader> _parsePathToMapEntries(String path) {
  final songId = path.split(Platform.pathSeparator).last.split('_').first;
  return MapEntry(songId, SimpleAudioLoader(path: path));
}

Future<_CorrectChords> _getCorrectChords() async {
  final input = File('assets/csv/correct_only_sharp.csv').openRead();
  final fields = await input
      .transform(utf8.decoder)
      .transform(const CsvToListConverter())
      .toList();

  //ignore header
  return Map.fromEntries(
    fields.sublist(1).map((e) => MapEntry(
          e.first.toString(),
          ChordProgression(
              e.sublist(1).map((e) => Chord.fromLabel(e)).toList()),
        )),
  );
}
