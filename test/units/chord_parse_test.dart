import 'package:chord/domains/chord.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';

class _ChordTestCase {
  const _ChordTestCase(this.input, this.expected, this.indexes);

  final String input;
  final String expected;
  final Set<int> indexes;
}

class _DegreeChordTestCase {
  const _DegreeChordTestCase(this.input, this.expected);

  final String input;
  final String expected;
}

void main() {
  group('chord', () {
    const testCases = [
      _ChordTestCase('C', 'C', {0, 4, 7}),
      _ChordTestCase('Cm7', 'Cm7', {0, 3, 7, 10}),
      _ChordTestCase('CM9', 'CM9', {0, 4, 7, 11, 2}),
      _ChordTestCase('D7', 'D7', {2, 6, 9, 0}),
      _ChordTestCase('A9', 'A9', {9, 1, 4, 7, 11}),
      _ChordTestCase('G#m', 'G#m', {8, 11, 3}),
      _ChordTestCase('C6', 'C6', {0, 4, 7, 9}),
      _ChordTestCase('F#M7', 'F#M7', {6, 10, 1, 5}),
      _ChordTestCase('Gadd9', 'Gadd9', {7, 9, 11, 2}),
      _ChordTestCase('Dsus4', 'Dsus4', {2, 7, 9}),
      _ChordTestCase('Asus2', 'Asus2', {9, 11, 4}),
      _ChordTestCase('Edim', 'Edim', {4, 7, 10}),
      _ChordTestCase('G#dim7', 'G#dim7', {8, 11, 2, 5}),
      _ChordTestCase('Caug', 'Caug', {0, 4, 8}),
      _ChordTestCase('C(omit5)', 'C(omit5)', {0, 4}),
      _ChordTestCase('Dm7(omit5)', 'Dm7(omit5)', {2, 5, 0}),
    ];

    for (final testCase in testCases) {
      test(testCase.input, () {
        final chord = Chord.parse(testCase.input);
        logTest(chord.toString());
        logTest(chord.noteIndexes.toString(), title: 'actual');
        logTest(testCase.indexes.toString(), title: 'expect');

        expect(chord.toString(), testCase.expected);
        expect(setEquals(chord.noteIndexes, testCase.indexes), isTrue);
      });
    }
  });

  group('degree name', () {
    const testCases = [
      _DegreeChordTestCase('I', 'I'),
      _DegreeChordTestCase('Im7', 'Im7'),
      _DegreeChordTestCase('IIm6', 'IIm6'),
      _DegreeChordTestCase('III7', 'III7'),
      _DegreeChordTestCase('bIV', 'III'),
      _DegreeChordTestCase('V', 'V'),
      _DegreeChordTestCase('VIm7b5', 'VIm7b5'),
      _DegreeChordTestCase('#Idim7', 'bIIdim7'),
    ];

    for (final testCase in testCases) {
      test(
        testCase.input,
        () {
          final chord = DegreeChord.parse(testCase.input);
          expect(chord.toString(), testCase.expected);
        },
      );
    }
  });
}
