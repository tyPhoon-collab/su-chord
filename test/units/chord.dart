import 'package:chord/domains/chord.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const dMajor = [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0];

  test('major', () async {
    expect(Chord.major(root: Note.D).notes, [Note.D, Note.Fs, Note.A]);
  });

  test('major pcp', () async {
    expect(Chord.major(root: Note.D).pcp.values, dMajor);
  });
}
