import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/chroma_calculators/reassignment.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../writer.dart';

void main() {
  late final AudioData sampleData;
  late final AudioData noteC3Data;
  late final AudioData chordCData;
  late final Writer writer;

  setUpAll(() async {
    sampleData = await AudioLoader.sample.load(sampleRate: 22050);
    noteC3Data =
        await const SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav')
            .load(sampleRate: 22050);
    chordCData =
        await const SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav')
            .load(sampleRate: 22050);
    writer = const PCPChartWriter();
  });

  group('base', () {
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
  });

  group('reassignment', () {
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
      final chromas =
          ReassignmentChromaCalculator()(sampleData.cut(duration: 4));
      final chroma = chromas[0].normalized;

      expect(chroma, isNotNull);
    });
  });

  group('comb filter', () {
    test('one note', () async {
      final chroma = CombFilterChromaCalculator(
              magnitudesCalculable: MagnitudesCalculator())(noteC3Data)
          .first;

      debugPrint(chroma.toString());
      expect(chroma.maxIndex, 0);
    });

    test('chord', () async {
      final chroma = CombFilterChromaCalculator(
              magnitudesCalculable: MagnitudesCalculator())(chordCData)
          .first;

      expect(chroma, isNotNull);
    });

    test('std dev coef', () async {
      final f = factory8192_0;
      final data = sampleData.cut(duration: 4);

      const contexts = [
        CombFilterContext(hzStdDevCoefficient: 1 / 24),
        CombFilterContext(hzStdDevCoefficient: 1 / 48),
        // ignore: avoid_redundant_argument_values
        CombFilterContext(hzStdDevCoefficient: 1 / 72),
        CombFilterContext(hzStdDevCoefficient: 1 / 96),
      ];

      for (final c in contexts) {
        final chroma = f.filter
            .interval(4.seconds)(
              CombFilterChromaCalculator(
                magnitudesCalculable: f.magnitude.stft(),
                context: c,
              ).call(data),
            )
            .first
            .normalized;

        writer(chroma, title: c.toString());
      }
    });

    test('log vs normal', () async {
      final data = sampleData.cut(duration: 4);

      final filter = factory8192_0.filter.interval(4.seconds);

      debugPrint(filter(
        factory8192_0.bigRange.combFilter().call(data),
      ).first.normalized.toString());

      debugPrint(filter(
        factory8192_0.bigRange
            .combFilter(
                magnitudesCalculable: factory8192_0.magnitude.stft(
              scalar: MagnitudeScalar.ln,
            ))
            .call(data),
      ).first.normalized.toString());
    });

    test('guitar tuning', () async {
      final ccd = factory8192_0.filter.interval(3.seconds);
      final chromas = ccd(factory8192_0.guitarRange
          .combFilter()
          .call(sampleData.cut(duration: 4)));

      expect(chromas[0], isNotNull);
    });
  });

  test('cosine similarity', () {
    final f = factory8192_0;
    final chromas = f.guitarRange
        .reassignCombFilter()
        .call(sampleData.cut(duration: 4, offset: 12));

    final pcp = f.filter.interval(4.seconds).call(chromas).first;
    final template = PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]).normalized;
    writer(pcp.cosineSimilarity(template));
  });

  test('compare cosine similarity', () async {
    final ccd = factory8192_0.filter.interval(3.seconds);

    Measure.logger = null;

    final calculator = [
      factory8192_0.guitarRange.combFilter(),
      factory8192_0.guitarRange.combFilter(
        combFilterContext: const CombFilterContext(hzStdDevCoefficient: 1 / 96),
      ),
      factory8192_0.guitarRange.combFilter(
        magnitudesCalculable:
            factory8192_0.magnitude.stft(scalar: MagnitudeScalar.ln),
      ),
      // factory8192_0.guitarRange.combFilterWith(scalar: MagnitudeScalar.dB),
      factory8192_0.guitarRange.reassignment(),
      factory8192_0.guitarRange.reassignment(scalar: MagnitudeScalar.ln),
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
      final chroma = ccd(c(chordCData)).first;
      debugPrint('chroma: ${chroma.normalized}');
      for (final value in templates) {
        debugPrint(
            'cosine similarity: ${chroma.cosineSimilarity(value.pcp).toStringAsFixed(3)} of $value');
      }
      debugPrint('');
    }
  });

  test('compare chroma', () async {
    final data = sampleData.cut(duration: 4);
    final f = factory8192_0;
    final cs = [
      for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
        f.guitarRange
            .combFilter(magnitudesCalculable: f.magnitude.stft(scalar: scalar)),
        f.guitarRange.combFilter(
            magnitudesCalculable: f.magnitude.reassignment(scalar: scalar)),
        f.guitarRange.reassignment(scalar: scalar),
      ]
    ];
    final filter = f.filter.interval(4.seconds);

    for (final c in cs) {
      final chroma = filter(c(data)).first.normalized;
      writer(chroma, title: c.toString());
    }
  });
}
