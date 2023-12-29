import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../writer.dart';
import 'comparator.dart';

void main() {
  final f = factory4096_0;

  group('compare spot plot', () {
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

    test('A 1 3', () async {
      await compare(
        source: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav',
        index: 3,
        chords: [
          Chord.parse('C'),
          Chord.parse('Cm'),
          Chord.parse('C7'),
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

    test('C F', () async {
      await compare(
        source: 'assets/evals/HojoGuitar/5_Hojo.wav',
        index: 1,
        chords: [
          Chord.parse('F'),
          Chord.parse('Faug'),
          Chord.parse('C#aug'),
        ],
      );
    });

    test('D F', () async {
      await compare(
        source: 'assets/evals/RealStrat/5_涙の天使に-01.wav',
        index: 1,
        chords: [
          Chord.parse('F'),
          Chord.parse('Faug'),
          Chord.parse('C#aug'),
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

    test('B Em', () async {
      await compare(
          source:
              'assets/evals/Halion_CleanStratGuitar/7_Halion_CleanStratGuitar.wav',
          index: 2,
          chords: [
            Chord.parse('Em'),
            Chord.parse('Em7'),
          ]);
    });

    test('B A#M7', () async {
      await compare(
          source:
              'assets/evals/Halion_CleanStratGuitar/9_Halion_CleanStratGuitar.wav',
          index: 3,
          chords: [
            Chord.parse('A#'),
            Chord.parse('A#M7'),
            Chord.parse('A#add9'),
          ]);
    });

    test('B C', () async {
      await compare(
          source:
              'assets/evals/Halion_CleanStratGuitar/7_Halion_CleanStratGuitar.wav',
          index: 6,
          chords: [
            Chord.parse('C'),
            Chord.parse('CM7'),
            Chord.parse('Cadd9'),
          ]);
    });
  });

  group('compare mean template score', () {
    final f = factory4096_0;
    final compare = MeanScoreSpotComparator(
      chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      scalar: HarmonicsChromaScalar(until: 6),
      meanScalar: const LogChromaScalar(),
    );

    test('C', () async {
      await compare(
        source: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav',
        index: 3,
      );
    });

    test('F#m7b5', () async {
      await compare(
        source: 'assets/evals/Halion_CleanGuitarVX/2_東京-03.wav',
        index: 2,
      );
    });

    test('Am7b5', () async {
      await compare(
        source: 'assets/evals/Halion_CleanGuitarVX/5_涙の天使に.wav',
        index: 4,
      );
    });

    test('Dadd9', () async {
      await compare(
        source:
            'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav',
        index: 10,
      );
    });

    test('A#dim', () async {
      await compare(
        source: 'assets/evals/Halion_CleanGuitarVX/7_愛が生まれた日.wav',
        index: 8,
      );
    });

    test('Em', () async {
      await compare(
        source:
            'assets/evals/Halion_CleanStratGuitar/7_Halion_CleanStratGuitar.wav',
        index: 2,
      );
    });

    test('7 C#m7b5', () async {
      await compare(
        source:
            'assets/evals/Halion_CleanStratGuitar/7_Halion_CleanStratGuitar.wav',
        index: 5,
      );
    });

    test('8 C#m7b5', () async {
      await compare(
        source:
            'assets/evals/Halion_CleanStratGuitar/8_Halion_CleanStratGuitar.wav',
        index: 4,
      );
    });
  });

  test('compare chroma calc', () async {
    final f = factory4096_0;
    final chord = Chord.C;

    final template =
        HarmonicsChromaScalar(until: 6).call(chord.unitPCP).l2normalized;

    final cc = [
      f.guitar.reassignment(),
      f.guitar.reassignment(scalar: MagnitudeScalar.ln),
      f.guitar.reassignCombFilter(),
      f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln)
    ];

    for (final value in cc) {
      final pcp = average(value(await DataSet().C)).first;
      final score = const ScoreCalculator.cosine().call(pcp, template);

      logTest(score, title: value.toString());
    }
  });
}
