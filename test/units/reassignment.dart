import 'package:chord/domains/chroma_calculators/reassignment.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late final AudioData sampleData;
  late final AudioData noteC3Data;
  late final AudioData chordCData;

  setUpAll(() async {
    sampleData = await AudioLoader.sample.load(sampleRate: 22050);
    noteC3Data =
        await const SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav')
            .load(sampleRate: 22050);
    chordCData =
        await const SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav')
            .load(sampleRate: 22050);
  });

  test('one note', () async {
    final chroma = ReassignmentChromaCalculator()(noteC3Data).first;

    debugPrint(chroma.toString());
    expect(chroma.maxIndex, 0);
  });

  test('chord', () async {
    final chroma = ReassignmentChromaCalculator()(chordCData).first;

    expect(chroma.maxIndex, 0);
  });

  test('long duration', () async {
    final chromas = ReassignmentChromaCalculator()(sampleData);

    expect(chromas, isNotEmpty);
  });

  test('normalized', () async {
    final chromas = ReassignmentChromaCalculator()(sampleData.cut(duration: 4));
    final chroma = chromas[0].normalized;

    expect(chroma, isNotNull);
  });
}
