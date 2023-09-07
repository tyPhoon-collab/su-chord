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
      const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
      final data = await loader.load();
      final chroma = ReassignmentChromaCalculator()(data).first;

      debugPrint(chroma.toString());
      expect(chroma.maxIndex, 0);
    });

    test('chord', () async {
      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = ReassignmentChromaCalculator()(data);

      expect(chromas[0].maxIndex, 0);
    });

    test('long duration', () async {
      const loader = SimpleAudioLoader(
          path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
      final data = await loader.load(sampleRate: Config.sampleRate);
      final chromas = ReassignmentChromaCalculator()(data);

      expect(chromas, isNotEmpty);
    });

    test('normalized', () async {
      const loader = SimpleAudioLoader(
          path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = ReassignmentChromaCalculator()(data);
      final chroma = chromas[0].normalized;

      expect(chroma, isNotNull);
    });
  });

  group('comb filter', () {
    test('one note', () async {
      const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
      final data = await loader.load();
      final chroma = CombFilterChromaCalculator()(data).first;

      debugPrint(chroma.toString());
      expect(chroma.maxIndex, 0);
    });

    test('chord', () async {
      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = CombFilterChromaCalculator()(data);

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
            .interval(4.seconds)(CombFilterChromaCalculator(
              chunkSize: factory.context.chunkSize,
              chunkStride: factory.context.chunkStride,
              context: e,
            )(data))
            .first,
      );

      for (final e in chromas) {
        debugPrint(e.normalized.toString());
      }
    });

    test('log vs normal', () async {
      final factory = EstimatorFactory(const EstimatorFactoryContext(
        chunkSize: 8192,
        chunkStride: 0,
        sampleRate: 22050,
      ));

      final data = await AudioLoader.sample.load(
        duration: 4,
        sampleRate: factory.context.sampleRate,
      );

      final filter = factory.filter.interval(4.seconds);

      debugPrint(filter(
        CombFilterChromaCalculator(
          chunkSize: factory.context.chunkSize,
          chunkStride: factory.context.chunkStride,
        )(data),
      ).first.normalized.toString());

      debugPrint(filter(
        CombFilterChromaCalculator(
          chunkSize: factory.context.chunkSize,
          chunkStride: factory.context.chunkStride,
          scalar: MagnitudeScalar.log,
        )(data),
      ).first.normalized.toString());
    });

    test('guitar tuning', () async {
      const chunkSize = 8192;
      const chunkStride = 0;
      final c = CombFilterChromaCalculator(
        chunkSize: chunkSize,
        chunkStride: chunkStride,
        lowest: MusicalScale.E2,
        perOctave: 6,
      );
      final ccd = IntervalChordChangeDetector(
          interval: 3.seconds, dt: chunkSize / Config.sampleRate);

      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = ccd(c(data));

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
    final chroma1 = ccd(cc1(data)).first.normalized;
    final chroma2 = ccd(cc2(data)).first.normalized;

    expect(chroma1, isNotNull);
    expect(chroma2, isNotNull);
  });
}
