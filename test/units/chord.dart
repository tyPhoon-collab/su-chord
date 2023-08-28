import 'package:chord/domains/chord.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:flutter/cupertino.dart';
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
      Chord.fromType(type: ChordType.major, root: Note.D).pcp,
      [0, 0, 1, 0, 0, 0, 1, 0, 0, 1, 0, 0],
    );
  });

  test('equal', () {
    expect(Chord.fromLabel('C'), equals(Chord.fromLabel('C')));
    expect(Chord.fromLabel('CM7'), equals(Chord.fromLabel('CM7')));
  });

  group('chord label', () {
    test('maj', () {
      expect(
        Chord.fromType(type: ChordType.major, root: Note.C).label,
        'C',
      );
    });

    test('min', () {
      expect(
        Chord.fromType(type: ChordType.minor, root: Note.C).label,
        'Cm',
      );
    });

    test('dim', () {
      expect(
        Chord.fromType(type: ChordType.diminish, root: Note.C).label,
        'Cdim',
      );
    });

    test('aug', () {
      expect(
        Chord.fromType(type: ChordType.augment, root: Note.C).label,
        'Caug',
      );
    });

    test('sus4', () {
      expect(
        Chord.fromType(type: ChordType.sus4, root: Note.C).label,
        'Csus4',
      );
    });

    test('maj 7', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.seventh}),
        ).label,
        'C7',
      );
    });

    test('maj M7', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.majorSeventh}),
        ).label,
        'CM7',
      );
    });

    test('maj add9', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.ninth}),
        ).label,
        'Cadd9',
      );
    });

    test('maj 9,11', () {
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
  });

  group('parse label to chord', () {
    test('C', () {
      expect(Chord.fromLabel('C').label, 'C');
    });

    test('Cm', () {
      expect(Chord.fromLabel('Cm').label, 'Cm');
    });

    test('Cm7', () {
      expect(Chord.fromLabel('Cm7').label, 'Cm7');
    });

    test('C7', () {
      expect(Chord.fromLabel('C7').label, 'C7');
    });

    test('CM7', () {
      expect(Chord.fromLabel('CM7').label, 'CM7');
    });

    test('Cadd9', () {
      expect(Chord.fromLabel('Cadd9').label, 'Cadd9');
    });

    test('C6', () {
      expect(Chord.fromLabel('C6').label, 'C6');
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

  group('chord from notes', () {
    test('c e g -> C', () {
      final cs = Chord.fromNotes([Note.C, Note.E, Note.G]);
      expect(
        cs.singleOrNull,
        equals(Chord.fromType(
          type: ChordType.major,
          root: Note.C,
        )),
      );
    });

    test('c e g b -> CM7', () {
      final cs = Chord.fromNotes([Note.C, Note.E, Note.G, Note.B]);
      expect(
        cs.singleOrNull,
        equals(Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.majorSeventh}),
        )),
      );
    });

    test('c e g as -> C7', () {
      final cs = Chord.fromNotes([Note.C, Note.E, Note.G, Note.As]);
      expect(
        cs.singleOrNull,
        equals(Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.seventh}),
        )),
      );
    });

    test('c e g d -> Cadd9', () {
      final cs = Chord.fromNotes([Note.C, Note.E, Note.G, Note.D]);
      debugPrint(cs.length.toString());
      expect(
        cs.first,
        equals(Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.ninth}),
        )),
      );
    });

    test('c ds fs a -> Cdim7', () {
      final cs = Chord.fromNotes([Note.C, Note.Ds, Note.Fs, Note.A]);
      expect(
        cs.firstOrNull,
        equals(Chord.fromType(
          type: ChordType.diminish7,
          root: Note.C,
        )),
      );
    });

    test('c ds fs -> Cdim', () {
      final cs = Chord.fromNotes([Note.C, Note.Ds, Note.Fs]);
      expect(
        cs.firstOrNull,
        equals(Chord.fromType(
          type: ChordType.diminish,
          root: Note.C,
        )),
      );
    });

    test('c ds g as -> Cm7', () {
      final cs = Chord.fromNotes([Note.C, Note.Ds, Note.G, Note.As]);
      expect(
        cs.firstOrNull,
        equals(Chord.fromType(
          type: ChordType.minor,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.seventh}),
        )),
      );
    });
  });
}
