import 'package:chord/domains/chord.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('major', () async {
    expect(
      Chord.fromType(type: ChordType.major, root: Note.D).notes,
      [Note.D, Note.Fs, Note.A],
    );
  });

  test('major pcp', () async {
    expect(
      Chord.fromType(type: ChordType.minor, root: Note.D).pcp.values,
      [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    );
  });
}
