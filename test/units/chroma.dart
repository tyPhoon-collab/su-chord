import 'package:chord/config.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/loader/audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  test('norm', () async {
    final c1 = Chroma(const [1, 1, 1, 1]);
    expect(c1.l2norm, 2);

    final c2 = Chroma(const [-1, -1, -1, -1]);
    expect(c2.l2norm, 2);
  });

  test('normalized', () async {
    final c1 = Chroma(const [1, 1, 1, 1]);
    expect(c1.normalized, [0.5, 0.5, 0.5, 0.5]);

    final c2 = Chroma(const [-1, -1, -1, -1]);
    expect(c2.normalized, [-0.5, -0.5, -0.5, -0.5]);
  });

  test('cosine similarity', () async {
    final c1 = Chroma(const [1, 1, 1, 1]);
    expect(c1.cosineSimilarity(c1), 1);

    final c2 = Chroma(const [-1, -1, -1, -1]);
    expect(c1.cosineSimilarity(c2), -1);
  });

  group('reassignment', () {
    test('one note', () async {
      final c = ReassignmentChromaCalculator();

      const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
      final data = await loader.load();
      final chromas = c.chroma(data);

      expect(chromas[0].maxIndex, 0);
    });

    test('chord', () async {
      final c = ReassignmentChromaCalculator();

      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = c.chroma(data);

      expect(chromas[0].maxIndex, 0);
    });

    test('long duration', () async {
      final c = ReassignmentChromaCalculator();

      const loader = SimpleAudioLoader(
          path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
      final data = await loader.load(sampleRate: Config.sampleRate);
      final chromas = c.chroma(data);

      expect(chromas, isNotEmpty);
    });

    test('normalized', () async {
      final c = ReassignmentChromaCalculator();

      const loader = SimpleAudioLoader(
          path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = c.chroma(data);
      final chroma = chromas[0].normalized;

      expect(chroma, isNotNull);
    });
  });

  group('comb filter', () {
    test('chord', () async {
      final c = CombFilterChromaCalculator();

      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = c.chroma(data);

      expect(chromas[0], isNotNull);
    });

    test('std dev coef', () async {
      final factory = EstimatorFactory(const EstimatorFactoryContext(
        chunkSize: 8192,
        chunkStride: 0,
        sampleRate: 22050,
      ));

      final data = await AudioLoader.sample.load(
        duration: 4,
        sampleRate: factory.context.sampleRate,
      );

      const contexts = [
        CombFilterContext(stdDevCoefficient: 1 / 24),
        CombFilterContext(stdDevCoefficient: 1 / 48),
        CombFilterContext(stdDevCoefficient: 1 / 72),
        CombFilterContext(stdDevCoefficient: 1 / 96),
      ];

      final chromas = contexts.map(
        (e) => factory.filter
            .interval(4.seconds)
            .filter(CombFilterChromaCalculator(
              chunkSize: factory.context.chunkSize,
              chunkStride: factory.context.chunkStride,
              context: e,
            ).chroma(data))
            .toList(),
      );

      for (final e in chromas) {
        debugPrint(e.toString());
      }
    });

    test('guitar tuning', () async {
      const chunkSize = 8192;
      const chunkStride = 0;
      final c = CombFilterChromaCalculator(
          chunkSize: chunkSize,
          chunkStride: chunkStride,
          lowest: MusicalScale.E2,
          perOctave: 6);
      final ccd = IntervalChordChangeDetector(
          interval: 3.seconds, dt: chunkSize / Config.sampleRate);

      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = ccd.filter(c.chroma(data));

      expect(chromas[0], isNotNull);
    });
  });

  test('compare comb vs reassignment', () async {
    const chunkSize = 8192;
    const chunkStride = 0;
    // const chunkSize = Config.chunkSize;
    // const chunkStride = Config.chunkStride;

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
        interval: 3.seconds, dt: chunkSize / Config.sampleRate);

    // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);
    final chroma1 = ccd.filter(cc1.chroma(data)).first.normalized;
    final chroma2 = ccd.filter(cc2.chroma(data)).first.normalized;

    expect(chroma1, isNotNull);
    expect(chroma2, isNotNull);
  });
}
