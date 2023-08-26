import 'dart:convert';
import 'dart:io';

import 'package:chord/config.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimate.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/loader.dart';
import 'package:chord/utils/table.dart';
import 'package:collection/collection.dart';
import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

//Song ID : ChordProgression
typedef _CorrectChords = Map<String, ChordProgression>;
typedef _SongID = String;
typedef _Paths = Iterable<String>;

Future<void> main() async {
  const sampleRate = Config.sampleRate;

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
      data.add(_EvaluatorContext(
        key: int.parse(key),
        songId: songId,
        data: await entry.value.load(duration: 83, sampleRate: sampleRate),
        corrects: corrects[key]!,
      ));
    }
    data.sort((a, b) => a.key.compareTo(b.key));
  });

  group('prop', () {
    test('best', () async {
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: ReassignmentChromaCalculator(
            lowest: MusicalScale.E2,
            perOctave: 6,
          ),
          filters: [
            // ThresholdFilter(threshold: 100),
            IntervalChordChangeDetector(
              interval: 4,
              dt: Config.chunkStride / sampleRate,
            ),
          ],
        ),
      ).evaluate(data, path: 'test/outputs/prop.csv');
    });

    test('prop to conv chunkSize', () async {
      const chunkSize = 8192;
      const chunkStride = 0;
      const dt = chunkSize / sampleRate;
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: ReassignmentChromaCalculator(
            chunkSize: chunkSize,
            chunkStride: chunkStride,
            lowest: MusicalScale.E2,
            perOctave: 6,
          ),
          filters: [
            // ThresholdFilter(threshold: 100),
            IntervalChordChangeDetector(interval: 4, dt: dt),
          ],
        ),
      ).evaluate(data, path: 'test/outputs/prop.csv');
    });

    test('piano tuning', () async {
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
          chromaCalculable: ReassignmentChromaCalculator(),
          filters: [
            // ThresholdFilter(threshold: 100),
            IntervalChordChangeDetector(
              interval: 4,
              dt: Config.chunkStride / sampleRate,
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
      _Evaluator(
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
          thresholdRatio: 0.3,
        ),
      ).evaluate(data, path: 'test/outputs/conv.csv');
    });
  });

  group('control experiment', () {
    test('pattern matching + comb filter', () {
      const chunkSize = 8192;
      const chunkStride = 0;
      const dt = chunkSize / sampleRate;
      _Evaluator(
        estimator: PatternMatchingChordEstimator(
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
        ),
      ).evaluate(data);
    });

    test('search tree + reassignment', () async {
      const chunkSize = 8192;
      const chunkStride = 0;
      const dt = chunkSize / sampleRate;
      _Evaluator(
          estimator: SearchTreeChordEstimator(
        chromaCalculable: ReassignmentChromaCalculator(
          chunkSize: chunkSize,
          chunkStride: chunkStride,
          lowest: MusicalScale.E2,
          perOctave: 6,
        ),
        filters: [
          IntervalChordChangeDetector(interval: 4, dt: dt),
        ],
        thresholdRatio: 0.5,
      )).evaluate(data);
    });
  });

  test('eval conv lowest C1, octave 7', () async {
    _Evaluator(
        estimator: SearchTreeChordEstimator(
      chromaCalculable: CombFilterChromaCalculator(),
      filters: [
        IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / sampleRate,
        ),
      ],
    )).evaluate(data);
  });

  test('eval conv threshold changed', () async {
    _Evaluator(
        estimator: SearchTreeChordEstimator(
      chromaCalculable: CombFilterChromaCalculator(),
      filters: [
        IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / sampleRate,
        ),
      ],
      thresholdRatio: 0.3,
    )).evaluate(data);
  });
}

class _EvaluatorContext {
  const _EvaluatorContext({
    required this.key,
    required this.songId,
    required this.data,
    required this.corrects,
  });

  final int key;
  final _SongID songId;
  final AudioData data;
  final ChordProgression corrects;
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
