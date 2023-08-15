import 'package:chord/domains/chroma.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reassignment chroma one note', () async {
    final c = ReassignmentChromaCalculator();

    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
    final data = await loader.load();
    final chromas = c.chroma(data);

    expect(chromas[0].maxIndex(), 0);
  });

  test('reassignment chroma chord', () async {
    final c = ReassignmentChromaCalculator();

    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load();
    final chromas = c.chroma(data);

    expect(chromas[0].maxIndex(), 0);
  });

  test('reassignment chroma eval', () async {
    final c = ReassignmentChromaCalculator();

    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load();
    final chromas = c.chroma(data);

    expect(chromas, isNotEmpty);
  });
}
