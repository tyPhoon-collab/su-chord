import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_cell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('major', () {
    expect(
      Chord.fromType(type: ChordType.major, root: Note.D).notes,
      [Note.D, Note.Fs, Note.A],
    );
  });

  test('major pcp', () {
    expect(
      Chord.fromType(type: ChordType.major, root: Note.D).unitPCP,
      [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    );
  });

  group('equal', () {
    test('hashcode', () {
      expect(Chord.parse('C').hashCode, equals(Chord.parse('C').hashCode));
    });

    test('chord', () {
      expect(Chord.parse('C'), equals(Chord.parse('C')));
      expect(Chord.parse('C'), isNot(Chord.parse('Cm')));
      expect(Chord.parse('CM7'), equals(Chord.parse('CM7')));
    });

    test('degree name chord', () {
      expect(DegreeChord.parse('I'), equals(DegreeChord.parse('I')));
    });

    test('chord and degree name', () {
      expect(DegreeChord.parse('I'), isNot(Chord.parse('C')));
    });

    test('baseEqual', () {
      expect(DegreeChord.parse('I').baseEqual(DegreeChord.parse('I')), true);
      expect(DegreeChord.parse('I').baseEqual(Chord.parse('C')), true);
    });
  });

  group('chord label', () {
    test('maj', () {
      expect(
        Chord.fromType(type: ChordType.major, root: Note.C).toString(),
        'C',
      );
    });

    test('min', () {
      expect(
        Chord.fromType(type: ChordType.minor, root: Note.C).toString(),
        'Cm',
      );
    });

    test('dim', () {
      expect(
        Chord.fromType(type: ChordType.diminish, root: Note.C).toString(),
        'Cdim',
      );
    });

    test('aug', () {
      expect(
        Chord.fromType(type: ChordType.augment, root: Note.C).toString(),
        'Caug',
      );
    });

    test('sus4', () {
      expect(
        Chord.fromType(type: ChordType.sus4, root: Note.C).toString(),
        'Csus4',
      );
    });

    test('maj 7', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: ChordTensions.seventh,
        ).toString(),
        'C7',
      );
    });

    test('maj M7', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: ChordTensions.majorSeventh,
        ).toString(),
        'CM7',
      );
    });

    test('sus4 7', () {
      expect(
        Chord.fromType(
          type: ChordType.sus4,
          root: Note.C,
          tensions: ChordTensions.seventh,
        ).toString(),
        'C7sus4',
      );
    });

    test('maj add9', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: const ChordTensions({ChordTension.ninth}),
        ).toString(),
        'Cadd9',
      );
    });

    test('maj 9,11', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: const ChordTensions({
            ChordTension.ninth,
            ChordTension.eleventh,
          }),
        ).toString(),
        'C(9,11)',
      );
    });
  });

  // group('chord type from notes and root', () {
  //   test('c e g, c -> maj', () {
  //     final cts = ChordType.fromNotes([Note.C, Note.E, Note.G], Note.C);
  //     expect(cts.singleOrNull, ChordType.major);
  //   });
  //
  //   test('d fs a, d -> maj', () {
  //     final cts = ChordType.fromNotes([Note.D, Note.Fs, Note.A], Note.D);
  //     expect(cts.singleOrNull, ChordType.major);
  //   });
  //
  //   test('c ds g -> min', () {
  //     final cts = ChordType.fromNotes([Note.C, Note.Ds, Note.G], Note.C);
  //     expect(cts.singleOrNull, ChordType.minor);
  //   });
  // });

  group('degree to chord', () {
    test(
      'Im7 to Cm7 in C',
      () => expect(
        DegreeChord.parse('Im7').toChordFromKey(Note.C),
        equals(Chord.parse('Cm7')),
      ),
    );

    test(
      'IIm7 to Dm7 in C',
      () => expect(
        DegreeChord.parse('IIm7').toChordFromKey(Note.C),
        equals(Chord.parse('Dm7')),
      ),
    );
  });
}
