import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/measure.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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
    final f = f_8192;
    final chromas =
        f.guitar.reassignCombFilter().call(await DataSet().G_Em_Bm_C);

    final pcp = chromas.average(f.hcdf.eval.call(chromas)).first;
    final template =
        PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]).l2normalized;
    debugPrint(const CosineSimilarity().call(pcp, template).toString());
  });

  test('compare cosine similarity', () async {
    final f = f_8192;

    Measure.logger = null;

    final calculator = [
      f.guitar.combFilter(),
      f.guitar.combFilter(
        combFilterContext: const CombFilterContext(hzStdDevCoefficient: 1 / 96),
      ),
      f.guitar.stftCombFilter(scalar: MagnitudeScalar.ln),
      // f_8192.guitarRange.combFilterWith(scalar: MagnitudeScalar.dB),
      f.guitar.reassignment(),
      f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    ];

    final templates = [
      Chord.fromType(type: ChordType.major, root: Note.C),
      Chord.fromType(
        type: ChordType.major,
        root: Note.C,
        tensions: ChordTensions.majorSeventh,
      ),
    ];

    for (final c in calculator) {
      final chroma = c(await DataSet().osawa.C).average().first;
      debugPrint('chroma: ${chroma.l2normalized}');
      for (final value in templates) {
        final cs = const CosineSimilarity().call(chroma, value.unitPCP);
        debugPrint('cos sim: ${cs.toStringAsFixed(3)} of $value');
      }
      debugPrint('');
    }
  });

  test('compare chroma', () async {
    final f = f_8192;
    final cs = [
      for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
        f.guitar.stftCombFilter(scalar: scalar),
        f.guitar.reassignCombFilter(scalar: scalar),
        f.guitar.reassignment(scalar: scalar),
      ]
    ];
    for (final c in cs) {
      final chroma = c(await DataSet().G).average().first.l2normalized;
      debugPrint(chroma.toString());
    }
  });
}
