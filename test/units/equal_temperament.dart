import 'package:chord/domains/equal_temperament.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('note degree of C to G is 7', () {
    const note = Note.C;
    final int degree = note.degreeTo(Note.G);
    expect(degree, 7);
  });

  test('note degree of D to C is -2', () {
    const note = Note.D;
    final int degree = note.degreeTo(Note.C);
    expect(degree, -2);
  });

  test('music scale degree of A0 to C1 is 3', () {
    final scale = MusicalScale.A0;
    final int degree = scale.degreeTo(MusicalScale(Note.C, 1));
    expect(degree, 3);
  });

  test('music scale degree of C1 to C2 is 12', () {
    final scale = MusicalScale(Note.C, 1);
    final int degree = scale.degreeTo(MusicalScale(Note.C, 2));
    expect(degree, 12);
  });

  test('music scale degree of C3 to C2 is -12', () {
    final scale = MusicalScale(Note.C, 3);
    final int degree = scale.degreeTo(MusicalScale(Note.C, 2));
    expect(degree, -12);
  });

  test('note C to 2 be D', () {
    expect(Note.C.to(2), Note.D);
  });

  test('note C to 14 be D', () {
    expect(Note.C.to(2), Note.D);
  });

  test('note C to -3 be A', () {
    expect(Note.C.to(-3), Note.A);
  });
}
