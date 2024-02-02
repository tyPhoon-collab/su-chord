import 'package:chord/domains/chord.dart';
import 'package:chord/domains/musical_label.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestCase {
  const _TestCase(this.actual, this.normal, this.verbose, this.jazz);

  _TestCase.chord(String label, this.normal, this.verbose, this.jazz)
      : actual = Chord.parse(label);

  final Object actual;
  final String normal;
  final String verbose;
  final String jazz;

  void _expect() {
    MusicalLabel.type = L.normal;
    expect(actual.toString(), normal);
    MusicalLabel.type = L.verbose;
    expect(actual.toString(), verbose);
    MusicalLabel.type = L.jazz;
    expect(actual.toString(), jazz);
  }
}

void main() {
  test('accidental', () {
    final testCases = [
      _TestCase(Accidental.natural.label, '', '♮', ''),
      _TestCase(Accidental.sharp.label, '#', '♯', '#'),
      _TestCase(Accidental.flat.label, 'b', '♭', 'b'),
    ];

    for (final testCase in testCases) {
      testCase._expect();
    }
  });

  test('chord', () {
    final testCases = [
      _TestCase.chord('C', 'C', 'C♮', 'C'),
      _TestCase.chord('CM7', 'CM7', 'C♮maj7', 'C△7'),
      _TestCase.chord('Am7', 'Am7', 'A♮m7', 'A-7'),
      _TestCase.chord('F#m7b5', 'F#m7b5', 'F♯m7(♭5)', 'F#ø'),
    ];

    for (final testCase in testCases) {
      testCase._expect();
    }
  });
}
