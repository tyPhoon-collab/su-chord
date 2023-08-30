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
          qualities: ChordQualities.seventh,
        ).toString(),
        'C7',
      );
    });

    test('maj M7', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities.majorSeventh,
        ).toString(),
        'CM7',
      );
    });

    test('sus4 7', () {
      expect(
        Chord.fromType(
          type: ChordType.sus4,
          root: Note.C,
          qualities: ChordQualities.seventh,
        ).toString(),
        'C7sus4',
      );
    });

    test('maj add9', () {
      expect(
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          qualities: ChordQualities(const {ChordQuality.ninth}),
        ).toString(),
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
        ).toString(),
        'C(9,11)',
      );
    });
  });

  group('parse', () {
    group('chord', () {
      test('C', () {
        final c = Chord.parse('C');
        expect(c.toString(), 'C');
        expect(c.type, ChordType.major);
        expect(c.root, Note.C);
      });

      test('C', () {
        expect(Chord.parse('C').toString(), 'C');
      });

      test('Cm', () {
        expect(Chord.parse('Cm').toString(), 'Cm');
      });

      test('Cm7', () {
        expect(Chord.parse('Cm7').toString(), 'Cm7');
      });

      test('C7', () {
        expect(Chord.parse('C7').toString(), 'C7');
      });

      test('CM7', () {
        expect(Chord.parse('CM7').toString(), 'CM7');
      });

      test('Cadd9', () {
        expect(Chord.parse('Cadd9').toString(), 'Cadd9');
      });

      test('C6', () {
        expect(Chord.parse('C6').toString(), 'C6');
      });

      test('Cdim', () {
        expect(Chord.parse('Cdim').toString(), 'Cdim');
      });

      test('Cdim7', () {
        expect(Chord.parse('Cdim7').toString(), 'Cdim7');
      });
    });

    group('degree name', () {
      test(
        'I',
        () => expect(
          DegreeChord.parse('I'),
          equals(DegreeChord(DegreeName.I, type: ChordType.major)),
        ),
      );

      test(
        'bIV',
        () => expect(
          DegreeChord.parse('bIV'),
          equals(DegreeChord(DegreeName.III, type: ChordType.major)),
        ),
      );

      test(
        '#Idim7',
        () => expect(
          DegreeChord.parse('#Idim7'),
          equals(DegreeChord(DegreeName.bII, type: ChordType.diminish7)),
        ),
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
          qualities: ChordQualities.majorSeventh,
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
          qualities: ChordQualities.seventh,
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
          qualities: ChordQualities.seventh,
        )),
      );
    });
  });
}
