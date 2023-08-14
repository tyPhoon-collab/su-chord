import 'package:chord/domains/chroma.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('reassignment chroma', () async {
    final c = ReassignmentChromaCalculator();

    // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
    final data = await loader.load();
    final chromaList = c.chroma(data);

    expect(chromaList, isNotEmpty);
  });
}
