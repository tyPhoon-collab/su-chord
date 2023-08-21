import 'dart:convert';
import 'dart:io';

import 'package:chord/config.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_change_detector.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimate.dart';
import 'package:chord/utils/loader.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

//Song ID : ChordProgression
typedef _CorrectChords = Map<String, ChordProgression>;
typedef _SongID = String;

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
          ChordProgression(e.sublist(1).map((e) => Chord.fromLabel(e))),
        )),
  );
}

class Evaluator {
  Evaluator({required this.estimator});

  final ChordEstimable estimator;

  void eval(AudioData data, ChordProgression corrects) {
    final chords = estimator.estimate(data);

    debugPrint(chords.toString());
    debugPrint(corrects.toString());
  }
}

Future<void> main() async {
  final corrects = await _getCorrectChords();
  const loaders = <_SongID, AudioLoader>{
    '1':
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav'),
  };
  final data = <AudioData>[];

  setUpAll(() async {
    debugPrint('audio data is loading');

    for (final loader in loaders.values) {
      data.add(await loader.load(sampleRate: Config.sampleRate));
    }
    debugPrint('audio data was loaded');
  });

  test('eval prop', () async {
    for (int i = 0; i < data.length; i++) {
      Evaluator(
          estimator: PatternMatchingChordEstimator(
        chromaCalculable: ReassignmentChromaCalculator(),
        chordChangeDetectable: IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      )).eval(data[i], corrects[loaders.keys.toList()[i]]!);
    }
  });

  test('eval pattern matching with comb filter', () async {
    for (int i = 0; i < data.length; i++) {
      Evaluator(
          estimator: PatternMatchingChordEstimator(
        chromaCalculable: CombFilterChromaCalculator(),
        chordChangeDetectable: IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      )).eval(data[i], corrects[loaders.keys.toList()[i]]!);
    }
  });

  test('eval search tree with reassignment', () async {
    for (int i = 0; i < data.length; i++) {
      Evaluator(
          estimator: SearchTreeChordEstimator(
        chromaCalculable: ReassignmentChromaCalculator(),
        chordChangeDetectable: IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      )).eval(data[i], corrects[loaders.keys.toList()[i]]!);
    }
  });

  test('eval conv', () async {
    const chunkSize = 8192;
    const chunkStride = 0;
    for (int i = 0; i < data.length; i++) {
      Evaluator(
          estimator: SearchTreeChordEstimator(
        chromaCalculable: CombFilterChromaCalculator(
          chunkSize: chunkSize,
          chunkStride: chunkStride,
          lowest: MusicalScale.E2,
          perOctave: 6,
        ),
        chordChangeDetectable: IntervalChordChangeDetector(
          interval: 4,
          dt: chunkSize / Config.sampleRate,
        ),
      )).eval(data[i], corrects[loaders.keys.toList()[i]]!);
    }
  });

  test('eval conv lowest C1, octave 7', () async {
    for (int i = 0; i < data.length; i++) {
      Evaluator(
          estimator: SearchTreeChordEstimator(
        chromaCalculable: CombFilterChromaCalculator(),
        chordChangeDetectable: IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
      )).eval(data[i], corrects[loaders.keys.toList()[i]]!);
    }
  });

  test('eval conv threshold changed', () async {
    for (int i = 0; i < data.length; i++) {
      Evaluator(
          estimator: SearchTreeChordEstimator(
        chromaCalculable: CombFilterChromaCalculator(),
        chordChangeDetectable: IntervalChordChangeDetector(
          interval: 4,
          dt: Config.chunkStride / Config.sampleRate,
        ),
        thresholdRatio: 0.3,
      )).eval(data[i], corrects[loaders.keys.toList()[i]]!);
    }
  });
}
