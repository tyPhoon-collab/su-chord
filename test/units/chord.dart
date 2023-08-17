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
      Chord.fromType(type: ChordType.major, root: Note.D).pcp.values,
      [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    );
  });

  test('chord maj', () {
    expect(
      Chord.fromType(type: ChordType.major, root: Note.C).label,
      'C',
    );
  });

  test('chord min', () {
    expect(
      Chord.fromType(type: ChordType.minor, root: Note.C).label,
      'Cm',
    );
  });

  test('chord dim', () {
    expect(
      Chord.fromType(type: ChordType.diminish, root: Note.C).label,
      'Cdim',
    );
  });

  test('chord aug', () {
    expect(
      Chord.fromType(type: ChordType.augment, root: Note.C).label,
      'Caug',
    );
  });

  test('chord sus4', () {
    expect(
      Chord.fromType(type: ChordType.sus4, root: Note.C).label,
      'Csus4',
    );
  });

  test('chord maj 7', () {
    expect(
      Chord.fromType(
        type: ChordType.major,
        root: Note.C,
        qualities: ChordQualities(const {ChordQuality.seventh}),
      ).label,
      'C7',
    );
  });

  test('chord maj M7', () {
    expect(
      Chord.fromType(
        type: ChordType.major,
        root: Note.C,
        qualities: ChordQualities(const {ChordQuality.majorSeventh}),
      ).label,
      'CM7',
    );
  });

  test('chord maj add9', () {
    expect(
      Chord.fromType(
        type: ChordType.major,
        root: Note.C,
        qualities: ChordQualities(const {ChordQuality.ninth}),
      ).label,
      'Cadd9',
    );
  });

  test('chord maj 9,11', () {
    expect(
      Chord.fromType(
        type: ChordType.major,
        root: Note.C,
        qualities: ChordQualities(const {
          ChordQuality.ninth,
          ChordQuality.eleventh,
        }),
      ).label,
      'C(9,11)',
    );
  });
}
