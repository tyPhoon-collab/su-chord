import 'package:chord/domains/chord.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/factory.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';
import 'comparator.dart';

void main() {
  final f = factory4096_0;

  final compare = SpotComparator(
    chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    writer: const PCPChartWriter(),
  );
  test('A 12 10', () async {
    await compare(
      source:
          'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav',
      index: 10,
      chords: [
        Chord.parse('Asus4'),
        Chord.parse('Dadd9'),
      ],
    );
  });

  test('D 11 1', () async {
    await compare(
      source: 'assets/evals/RealStrat/11_RealStrat_Elite.wav',
      index: 1,
      chords: [
        Chord.parse('C'),
        Chord.parse('Cadd9'),
      ],
    );
  });

  test('A 11 1', () async {
    await compare(
      source:
          'assets/evals/Halion_CleanGuitarVX/11_107_Halion_CleanGuitarVX.wav',
      index: 1,
      chords: [
        Chord.parse('C'),
        Chord.parse('Cadd9'),
      ],
    );
  });

  test('A 2 2', () async {
    await compare(
      source: 'assets/evals/Halion_CleanGuitarVX/2_東京-03.wav',
      index: 2,
      chords: [
        Chord.parse('F#m7b5'),
        Chord.parse('Am6'),
      ],
    );
  });
}
