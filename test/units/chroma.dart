import 'package:chord/config.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/chroma_calculators/magnitudes_calculator.dart';
import 'package:chord/domains/chroma_calculators/reassignment.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/measure.dart';
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
      final chroma = CombFilterChromaCalculator(
              magnitudesCalculable: MagnitudesCalculator())(data)
          .first;

      debugPrint(chroma.toString());
      expect(chroma.maxIndex, 0);
    });

    test('chord', () async {
      const loader =
          SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
      final data =
          await loader.load(duration: 4, sampleRate: Config.sampleRate);
      final chromas = CombFilterChromaCalculator(
          magnitudesCalculable: MagnitudesCalculator())(data);

      expect(chromas[0], isNotNull);
    });

    test('std dev coef', () async {
      final data = await AudioLoader.sample.load(
        duration: 4,
        sampleRate: factory8192_0.context.sampleRate,
      );

      const contexts = [
        CombFilterContext(hzStdDevCoefficient: 1 / 24),
        CombFilterContext(hzStdDevCoefficient: 1 / 48),
        // ignore: avoid_redundant_argument_values
        CombFilterContext(hzStdDevCoefficient: 1 / 72),
        CombFilterContext(hzStdDevCoefficient: 1 / 96),
      ];

      final chromas = contexts.map(
        (e) => factory8192_0.filter
            .interval(4.seconds)(CombFilterChromaCalculator(
              magnitudesCalculable: factory8192_0.magnitude.stft(),
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
        factory8192_0.bigRange.combFilterWith(
            magnitudesCalculable: factory8192_0.magnitude.stft(
          scalar: MagnitudeScalar.ln,
        ))(data),
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

    Measure.logger = null;

    final calculator = [
      factory8192_0.guitarRange.combFilter,
      factory8192_0.guitarRange.combFilterWith(
        combFilterContext: const CombFilterContext(hzStdDevCoefficient: 1 / 96),
      ),
      factory8192_0.guitarRange.combFilterWith(
        magnitudesCalculable:
            factory8192_0.magnitude.stft(scalar: MagnitudeScalar.ln),
      ),
      // factory8192_0.guitarRange.combFilterWith(scalar: MagnitudeScalar.dB),
      factory8192_0.guitarRange.reassignment,
      factory8192_0.guitarRange.reassignmentWith(scalar: MagnitudeScalar.ln),
    ];

    final templates = [
      Chord.fromType(type: ChordType.major, root: Note.C),
      Chord.fromType(
        type: ChordType.major,
        root: Note.C,
        qualities: ChordQualities.majorSeventh,
      ),
    ];

    for (final c in calculator) {
      final chroma = ccd(c(data)).first;
      debugPrint('chroma: ${chroma.normalized}');
      for (final value in templates) {
        debugPrint(
            'cosine similarity: ${chroma.cosineSimilarity(value.pcp).toStringAsFixed(3)} of $value');
      }
      debugPrint('');
    }
  });
}
