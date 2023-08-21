import 'package:chord/config.dart';
import 'package:chord/domains/chord_change_detector.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimate.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chroma cosine similarity', () async {
    final c1 = Chroma(const [1, 1, 1, 1]);
    expect(c1.cosineSimilarity(c1), 1);

    final c2 = Chroma(const [-1, -1, -1, -1]);
    expect(c1.cosineSimilarity(c2), -1);
  });

  test('reassignment chroma chord estimate', () async {
    final e = PatternMatchingChordEstimator(
      chromaCalculable: ReassignmentChromaCalculator(),
      chordChangeDetectable: IntervalChordChangeDetector(
        interval: 4,
        dt: Config.chunkStride / Config.sampleRate,
      ),
    );

    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load();
    final chords = e.estimate(data);

    expect(chords.length, 20);
  });
}
