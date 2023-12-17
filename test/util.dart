import 'dart:io';

import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/foundation.dart';

class AudioStreamEmulator {
  const AudioStreamEmulator({
    this.bufferChunkSize = 22050,
    this.sleepDuration = const Duration(seconds: 1),
  });

  final int bufferChunkSize;
  final Duration sleepDuration;

  Stream<AudioData> stream(AudioData data) async* {
    int seek = 0;

    while (seek < data.buffer.length) {
      final chunkData = data.cutByIndex(seek, seek + bufferChunkSize);
      seek += bufferChunkSize;
      yield chunkData;
      sleep(sleepDuration);
    }
  }
}

void printProgressions(
  ChordProgression progression, [
  ChordProgression? corrects,
]) {
  if (corrects != null) {
    printProgression('corrects', corrects);
  }
  printProgression('predicts', progression.simplify());
  printProgression('predict all', progression);
}

void printProgression(String label, ChordProgression progression) {
  debugPrint('$label(${progression.length})\t: $progression');
}

void printSeparation() {
  debugPrint('-' * 20);
}

extension Sanitize on Object {
  String sanitize() => toString()
      .replaceAll(RegExp(r'\s+'), '_')
      .replaceAll(',', '_')
      .replaceAll(':', '-');
}

///時間の配列とスコアの配列を返す
(List<double> time, List<double> score) getTimeAndScore(
  double deltaTime,
  List<Chroma> chroma,
  ScoreCalculator scoreCalculator, {
  double? nanTo,
  double Function(double)? mapper,
}) {
  Iterable<double> scores = List.generate(
    chroma.length - 1,
    (i) => scoreCalculator(chroma[i + 1], chroma[i]),
  );

  if (nanTo != null) {
    scores = scores.map((e) => e.isNaN ? nanTo : e);
  }
  if (mapper != null) {
    scores = scores.map(mapper);
  }

  final times = List.generate(chroma.length - 1, (i) => deltaTime * (i + 1));

  return (times, scores.toList());
}
