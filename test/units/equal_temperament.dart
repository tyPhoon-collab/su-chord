import 'package:chord/domains/equal_temperament.dart';
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

    group('degree', () {
      test('C to G is 7', () {
        const note = Note.C;
        final int degree = note.degreeTo(Note.G);
        expect(degree, 7);
      });

      test('D to C is -2', () {
        const note = Note.D;
        final int degree = note.degreeTo(Note.C);
        expect(degree, -2);
      });
    });
  });

  group('music scale', () {
    test('C3 to 2 is D3', () {
      final scale = MusicalScale(Note.C, 3);
      expect(scale.transpose(2), equals(MusicalScale(Note.D, 3)));
    });

    test('B3 to 1 is C4', () {
      final scale = MusicalScale(Note.B, 3);
      expect(scale.transpose(1), equals(MusicalScale(Note.C, 4)));
    });

    test('E2 to 12 * 6 is E8', () {
      final scale = MusicalScale.E2;
      expect(scale.transpose(12 * 6), equals(MusicalScale(Note.E, 8)));
    });

    group('degree', () {
      test('A0 to C1 is 3', () {
        final scale = MusicalScale.A0;
        final int degree = scale.degreeTo(MusicalScale(Note.C, 1));
        expect(degree, 3);
      });

      test('C1 to C2 is 12', () {
        final scale = MusicalScale(Note.C, 1);
        final int degree = scale.degreeTo(MusicalScale(Note.C, 2));
        expect(degree, 12);
      });

      test('C3 to C2 is -12', () {
        final scale = MusicalScale(Note.C, 3);
        final int degree = scale.degreeTo(MusicalScale(Note.C, 2));
        expect(degree, -12);
      });
    });
  });
}
