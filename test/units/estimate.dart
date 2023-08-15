import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reassignment chroma chord estimate', () async {
    final e = PatternMatchingChordEstimator(
      chromaCalculable: ReassignmentChromaCalculator(),
    );

    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load();
    final chords = e.estimate(data);

    expect(chords, isNotEmpty);
  });
}
