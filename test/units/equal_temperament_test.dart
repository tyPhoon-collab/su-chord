import 'package:chord/domains/equal_temperament.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('note', () {
    test('C to 2 be D', () {
      expect(Note.C.transpose(2), Note.D);
    });

    test('C to 14 be D', () {
      expect(Note.C.transpose(2), Note.D);
    });

    test('C to -3 be A', () {
      expect(Note.C.transpose(-3), Note.A);
    });

    group('to', () {
      group('to sharp', () {
        test('natural', () => expect(Note.C.toSharp(), Note.C));
        test('flat', () => expect(Note.Cb.toSharp(), Note.B));
        test('sharp', () => expect(Note.Cs.toSharp(), Note.Cs));
      });

      group('to flat', () {
        test('natural', () => expect(Note.C.toFlat(), Note.C));
        test('flat', () => expect(Note.Cb.toFlat(), Note.Cb));
        test('sharp', () => expect(Note.Cs.toFlat(), Note.Db));
      });
    });

    group('degree', () {
      test('C to G is 7', () {
        const note = Note.C;
        final int degree = note.degreeIndexTo(Note.G);
        expect(degree, 7);
      });

      test('D to C is -2', () {
        const note = Note.D;
        final int degree = note.degreeIndexTo(Note.C);
        expect(degree, -2);
      });
    });
  });

  group('music pitch', () {
    test('C3 to 2 is D3', () {
      const pitch = Pitch.C3;
      expect(pitch.transpose(2), equals(const Pitch(Note.D, 3)));
    });

    test('B3 to 1 is C4', () {
      const pitch = Pitch(Note.B, 3);
      expect(pitch.transpose(1), equals(const Pitch(Note.C, 4)));
    });

    test('C3 to -1 is B2', () {
      const pitch = Pitch.C3;
      expect(pitch.transpose(-1), equals(const Pitch(Note.B, 2)));
    });

    test('E2 to 12 * 6 is E8', () {
      const pitch = Pitch.E2;
      expect(pitch.transpose(12 * 6), equals(const Pitch(Note.E, 8)));
    });

    group('degree', () {
      test('A0 to C1 is 3', () {
        const pitch = Pitch.A0;
        final int degree = pitch.degreeIndexTo(Pitch.C1);
        expect(degree, 3);
      });

      test('C1 to C2 is 12', () {
        const pitch = Pitch.C1;
        final int degree = pitch.degreeIndexTo(const Pitch(Note.C, 2));
        expect(degree, 12);
      });

      test('C3 to C2 is -12', () {
        const pitch = Pitch.C3;
        final int degree = pitch.degreeIndexTo(const Pitch(Note.C, 2));
        expect(degree, -12);
      });
    });

    test('equal temperament bin', () {
      const lowest = Pitch.E2;
      const highest = Pitch.Ds8;
      final bin = equalTemperamentBin(lowest, highest);
      debugPrint(bin.toString());
      expect(bin.first, lessThan(lowest.toHz()));
      expect(lowest.transpose(1).toHz(), greaterThan(bin.first));
      expect(bin.last, greaterThan(highest.toHz()));
      expect(highest.transpose(-1).toHz(), lessThan(bin.last));
    });

    test('hz list', () {
      const lowest = Pitch.E2;
      const highest = Pitch(Note.E, 3);
      final l = Pitch.list(lowest, highest).toHzList();
      expect(l.first, lowest.toHz());
      expect(l.last, highest.toHz());
    });
  });
}
