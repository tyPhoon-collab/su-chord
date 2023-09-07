import 'package:chord/config.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/factory.dart';
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
      final data = await AudioLoader.sample.load(
        duration: 4,
        sampleRate: Config.sampleRate,
      );

      final filter = factory8192_0.filter.interval(4.seconds);

      debugPrint(filter(
        factory8192_0.bigRange.combFilter(data),
      ).first.normalized.toString());

      debugPrint(filter(
        factory8192_0.bigRange.combFilterLogScaling(data),
      ).first.normalized.toString());
    });

    test('guitar tuning', () async {
      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);

      final ccd = factory8192_0.filter.interval(3.seconds);
      final chromas = ccd(factory8192_0.guitarRange.combFilter(data));

      expect(chromas[0], isNotNull);
    });
  });

  test('compare chromas', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    // const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_g3.wav');
    final data = await loader.load(duration: 4, sampleRate: Config.sampleRate);

    final ccd = factory8192_0.filter.interval(3.seconds);

    final chromas = [
      ccd(factory8192_0.guitarRange.combFilter(data)).first.normalized,
      ccd(factory8192_0.guitarRange.reassignment(data)).first.normalized,
    ];

    for (final value in chromas) {
      debugPrint(value.toString());
    }
  });
}
