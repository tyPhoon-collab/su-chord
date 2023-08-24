import 'package:chord/config.dart';
import 'package:chord/domains/chord_change_detector.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chroma norm', () async {
    final c1 = Chroma(const [1, 1, 1, 1]);
    expect(c1.l2norm, 2);

    final c2 = Chroma(const [-1, -1, -1, -1]);
    expect(c2.l2norm, 2);
  });

  test('chroma normalized', () async {
    final c1 = Chroma(const [1, 1, 1, 1]);
    expect(c1.normalized, [0.5, 0.5, 0.5, 0.5]);

    final c2 = Chroma(const [-1, -1, -1, -1]);
    expect(c2.normalized, [-0.5, -0.5, -0.5, -0.5]);
  });

  test('reassignment chroma one note', () async {
    final c = ReassignmentChromaCalculator();

    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
    final data = await loader.load();
    final chromas = c.chroma(data);

    expect(chromas[0].maxIndex, 0);
  });

  test('reassignment chroma chord', () async {
    final c = ReassignmentChromaCalculator();

    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);
    final chromas = c.chroma(data);

    expect(chromas[0].maxIndex, 0);
  });

  test('reassignment chroma chord long duration', () async {
    final c = ReassignmentChromaCalculator();

    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(sampleRate: Config.sampleRate);
    final chromas = c.chroma(data);

    expect(chromas, isNotEmpty);
  });

  test('reassignment chroma chord normalized', () async {
    final c = ReassignmentChromaCalculator();

    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);
    final chromas = c.chroma(data);
    final chroma = chromas[0].normalized;

    expect(chroma, isNotNull);
  });

  test('comb chroma chord', () async {
    final c = CombFilterChromaCalculator();

    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);
    final chromas = c.chroma(data);

    expect(chromas[0], isNotNull);
  });

  test('comb chroma chord for guitar tuning', () async {
    const chunkSize = 8192;
    const chunkStride = 0;
    final c = CombFilterChromaCalculator(
        chunkSize: chunkSize,
        chunkStride: chunkStride,
        lowest: MusicalScale.E2,
        perOctave: 6);
    final ccd = IntervalChordChangeDetector(
        interval: 3, dt: chunkSize / Config.sampleRate);

    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);
    final chromas = ccd.filter(c.chroma(data));

    expect(chromas[0], isNotNull);
  });

  test('compare comb vs reassignment', () async {
    const chunkSize = 8192;
    const chunkStride = 0;

    final cc1 = CombFilterChromaCalculator(
        chunkSize: chunkSize,
        chunkStride: chunkStride,
        lowest: MusicalScale.E2,
        perOctave: 6);
    final cc2 = ReassignmentChromaCalculator(
        chunkSize: chunkSize,
        chunkStride: chunkStride,
        lowest: MusicalScale.E2,
        perOctave: 6);

    final ccd = IntervalChordChangeDetector(
        interval: 3, dt: chunkSize / Config.sampleRate);

    // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);
    final chromas1 = ccd.filter(cc1.chroma(data));
    final chromas2 = ccd.filter(cc2.chroma(data));

    expect(chromas1[0], isNotNull);
    expect(chromas2[0], isNotNull);
  });
}
