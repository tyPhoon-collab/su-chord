import 'dart:convert';
import 'dart:io';

import 'package:chord/config.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_change_detector.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimate.dart';
import 'package:chord/utils/loader.dart';
import 'package:csv/csv.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

//Song ID : ChordProgression
typedef _CorrectChords = Map<String, ChordProgression>;

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

void main() {
  test('eval', () async {
    final corrects = await _getCorrectChords();
    final estimator = PatternMatchingChordEstimator(
      chromaCalculable: ReassignmentChromaCalculator(),
      chordChangeDetectable: PerSecondChordChangeDetector(
        interval: 4,
        dt: Config.chunkStride / Config.sampleRate,
      ),
    );

    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(sampleRate: Config.sampleRate);
    final chords = estimator.estimate(data);

    debugPrint(chords.toString());
    debugPrint(corrects['1']!.toString());

    expect(chords.length, 20);
  });
}
