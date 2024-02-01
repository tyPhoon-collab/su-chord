// ignore_for_file: equal_elements_in_set

import 'package:chord/domains/chord.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';

class ChordTestCase {
  const ChordTestCase(this.input, this.expected, this.indexes);

  final String input;
  final String expected;
  final Set<int> indexes;
}

void main() {
  group('chord', () {
    const chordTestCases = [
      ChordTestCase('C', 'C', {0, 4, 7}),
      ChordTestCase('Cm7', 'Cm7', {0, 3, 7, 10}),
      ChordTestCase('D7', 'D7', {2, 6, 9, 0}),
      // ChordTestCase('Amaj9', 'Amaj9', {9, 1, 5, 8, 0}),
      ChordTestCase('G#m', 'G#m', {8, 11, 3}),
      ChordTestCase('C6', 'C6', {0, 4, 7, 9}),
      ChordTestCase('F#M7', 'F#M7', {6, 10, 1, 5}),
      ChordTestCase('Gadd9', 'Gadd9', {7, 9, 11, 2}),
      ChordTestCase('Dsus4', 'Dsus4', {2, 7, 9}),
      ChordTestCase('Asus2', 'Asus2', {9, 11, 4}),
      ChordTestCase('Edim', 'Edim', {4, 7, 10}),
      ChordTestCase('Caug', 'Caug', {0, 4, 8}),
      ChordTestCase('C(omit5)', 'C(omit5)', {0, 4}),
      // 他のテストケースも同様に追加可能
    ];

    for (final testCase in chordTestCases) {
      test(testCase.input, () {
        final chord = Chord.parse(testCase.input);
        logTest(chord.toString());
        logTest(chord.noteIndexes.toString());
        logTest(testCase.indexes.toString());

        expect(chord.toString(), testCase.expected);
        expect(setEquals(chord.noteIndexes, testCase.indexes), isTrue);
      });
    }
  });

  group('degree name', () {
    test(
      'I',
      () => expect(DegreeChord.parse('I').toString(), 'I'),
    );

    test(
      'Im7',
      () => expect(DegreeChord.parse('Im7').toString(), 'Im7'),
    );

    test(
      'IIm6',
      () => expect(DegreeChord.parse('IIm6').toString(), 'IIm6'),
    );

    test(
      'III7',
      () => expect(DegreeChord.parse('III7').toString(), 'III7'),
    );

    test(
      'bIV',
      () => expect(DegreeChord.parse('bIV').toString(), 'III'),
    );

    test(
      'V',
      () => expect(DegreeChord.parse('V').toString(), 'V'),
    );

    test(
      'VIm7b5',
      () => expect(DegreeChord.parse('VIm7b5').toString(), 'VIm7b5'),
    );

    test(
      '#Idim7',
      () => expect(DegreeChord.parse('#Idim7').toString(), 'bIIdim7'),
    );
  });
}
