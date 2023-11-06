import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../data_set.dart';

void main() {
  group('base', () {
    test('l1norm', () async {
      final c1 = Chroma(const [1, 1, 1, 1]);
      expect(c1.l1norm, 4);

      final c2 = Chroma(const [-1, -1, -1, -1]);
      expect(c2.l1norm, 4);
    });

    test('l2norm', () async {
      final c1 = Chroma(const [1, 1, 1, 1]);
      expect(c1.l2norm, 2);

      final c2 = Chroma(const [-1, -1, -1, -1]);
      expect(c2.l2norm, 2);
    });

    test('normalized', () async {
      final c1 = Chroma(const [1, 1, 1, 1]);
      expect(c1.l2normalized, [0.5, 0.5, 0.5, 0.5]);

      final c2 = Chroma(const [-1, -1, -1, -1]);
      expect(c2.l2normalized, [-0.5, -0.5, -0.5, -0.5]);
    });
  });

  test('cosine similarity', () async {
    final f = factory8192_0;
    final chromas =
        f.guitar.reassignCombFilter().call(await DataSet().G_Em_Bm_C);

    final pcp = f.filter.interval(4.seconds).call(chromas).first;
    final template =
        PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]).l2normalized;
    debugPrint(const CosineSimilarity().call(pcp, template).toString());
  });

  test('compare cosine similarity', () async {
    final ccd = factory8192_0.filter.interval(3.seconds);

    Measure.logger = null;

    final calculator = [
      factory8192_0.guitar.combFilter(),
      factory8192_0.guitar.combFilter(
        combFilterContext: const CombFilterContext(hzStdDevCoefficient: 1 / 96),
      ),
      factory8192_0.guitar.combFilter(
        magnitudesCalculable:
            factory8192_0.magnitude.stft(scalar: MagnitudeScalar.ln),
      ),
      // factory8192_0.guitarRange.combFilterWith(scalar: MagnitudeScalar.dB),
      factory8192_0.guitar.reassignment(),
      factory8192_0.guitar.reassignment(scalar: MagnitudeScalar.ln),
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
      final chroma = ccd(c(await DataSet().osawa.C)).first;
      debugPrint('chroma: ${chroma.l2normalized}');
      for (final value in templates) {
        final cs = const CosineSimilarity().call(chroma, value.unitPCP);
        debugPrint('cos sim: ${cs.toStringAsFixed(3)} of $value');
      }
      debugPrint('');
    }
  });

  test('compare chroma', () async {
    final f = factory8192_0;
    final cs = [
      for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
        f.guitar
            .combFilter(magnitudesCalculable: f.magnitude.stft(scalar: scalar)),
        f.guitar.combFilter(
            magnitudesCalculable: f.magnitude.reassignment(scalar: scalar)),
        f.guitar.reassignment(scalar: scalar),
      ]
    ];
    final filter = f.filter.interval(4.seconds);

    for (final c in cs) {
      final chroma = filter(c(await DataSet().G)).first.l2normalized;
      debugPrint(chroma.toString());
    }
  });
}
