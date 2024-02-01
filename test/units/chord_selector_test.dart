import 'package:chord/domains/chord_cell.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/domains/chord_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void _expect(
  ChordSelectable selector,
  ChordProgression<Chord> progression,
  List<Chord> before,
  List<Chord> after,
) {
  expect(
    listEquals(progression.toChordList(), before),
    isTrue,
  );
  expect(
    listEquals(selector(progression).toChordList(), after),
    isTrue,
  );
}

void main() {
  group('m7b5 selector', () {
    const selector = MinorFlatFiveChordSelector();
    test('1 down to simi tone', () {
      final progression = ChordProgression([
        ChordCell.of(Chord.C),
        MultiChordCell.first([
          Chord.parse('Am6'),
          Chord.parse('F#m7b5'),
        ]),
        ChordCell.of(Chord.F),
      ]);

      _expect(
        selector,
        progression,
        [Chord.C, Chord.parse('Am6'), Chord.F],
        [Chord.C, Chord.parse('F#m7b5'), Chord.F],
      );
    });
    test('1 starke Bassschritte', () {
      final progression = ChordProgression([
        ChordCell.of(Chord.C),
        MultiChordCell.first([
          Chord.parse('Dm6'),
          Chord.parse('Bm7b5'),
        ]),
        ChordCell.of(Chord.E),
      ]);

      _expect(
        selector,
        progression,
        [Chord.C, Chord.parse('Dm6'), Chord.E],
        [Chord.C, Chord.parse('Bm7b5'), Chord.E],
      );
    });
  });

  group('sixth selector', () {
    const selector = SixthChordSelector();
    test('2 down to simi tone m7b5', () {
      final progression = ChordProgression([
        ChordCell.of(Chord.C),
        MultiChordCell.first([
          Chord.parse('Am6'),
          Chord.parse('F#m7b5'),
        ]),
        ChordCell.of(Chord.F),
      ]);

      _expect(
        selector,
        progression,
        [Chord.C, Chord.parse('Am6'), Chord.F],
        [Chord.C, Chord.parse('F#m7b5'), Chord.F],
      );
    });
    test('2 starke Bassschritte m7b5', () {
      final progression = ChordProgression([
        ChordCell.of(Chord.C),
        MultiChordCell.first([
          Chord.parse('Dm6'),
          Chord.parse('Bm7b5'),
        ]),
        ChordCell.of(Chord.E),
      ]);

      _expect(
        selector,
        progression,
        [Chord.C, Chord.parse('Dm6'), Chord.E],
        [Chord.C, Chord.parse('Bm7b5'), Chord.E],
      );
    });

    test('2 down to simi tone m7', () {
      final progression = ChordProgression([
        ChordCell.of(Chord.F),
        MultiChordCell.first([
          Chord.parse('A6'),
          Chord.parse('Fm7'),
        ]),
        ChordCell.of(Chord.parse('Em7')),
      ]);

      _expect(
        selector,
        progression,
        [Chord.F, Chord.parse('A6'), Chord.parse('Em7')],
        [Chord.F, Chord.parse('Fm7'), Chord.parse('Em7')],
      );
    });
    test('2 starke Bassschritte m7', () {
      final progression = ChordProgression([
        ChordCell.of(Chord.C),
        MultiChordCell.first([
          Chord.parse('F6'),
          Chord.parse('Dm7'),
        ]),
        ChordCell.of(Chord.G),
      ]);

      _expect(
        selector,
        progression,
        [Chord.C, Chord.parse('F6'), Chord.G],
        [Chord.C, Chord.parse('Dm7'), Chord.G],
      );
    });
  });
}
