import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chord_search_tree.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('search tree', () {
    final searchChords = searchChordsClosure(Possible(DetectableChords.conv));

    test('c e g -> C et al.', () {
      _expectMultiFromString(
        searchChords([Note.C, Note.E, Note.G]),
        {'C', 'C7', 'CM7', 'C6', 'Cadd9', 'Am7'},
      );
    });
  });

  group('chord from notes', () {
    final searchChords = searchChordsClosure(Precise(DetectableChords.conv));

    test('c e g -> C', () {
      _expectSingle(
        searchChords([Note.C, Note.E, Note.G]),
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
        ),
      );
    });

    test('c e g b -> CM7', () {
      _expectSingle(
        searchChords([Note.C, Note.E, Note.G, Note.B]),
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: ChordTensions.majorSeventh,
        ),
      );
    });

    test('c e g as -> C7', () {
      _expectSingle(
        searchChords([Note.C, Note.E, Note.G, Note.As]),
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: ChordTensions.seventh,
        ),
      );
    });

    test('c e g d -> Cadd9', () {
      _expectSingle(
        searchChords([Note.C, Note.E, Note.G, Note.D]),
        Chord.fromType(
          type: ChordType.major,
          root: Note.C,
          tensions: ChordTensions(const {ChordTension.ninth}),
        ),
      );
    });

    test('c ds fs a -> Cdim7', () {
      _expectMultiFromString(
        searchChords([Note.C, Note.Ds, Note.Fs, Note.A]),
        {'Cdim7', 'D#dim7', 'F#dim7', 'Adim7'},
      );
    });

    test('c ds fs -> Cdim', () {
      _expectSingle(
        searchChords([Note.C, Note.Ds, Note.Fs]),
        Chord.fromType(
          type: ChordType.diminish,
          root: Note.C,
        ),
      );
    });

    test('c ds g as -> Cm7', () {
      _expectMultiFromString(
        searchChords([Note.C, Note.Ds, Note.G, Note.As]),
        {'Cm7', 'D#6'},
      );
    });
  });
}

void _expectSingle(
  Iterable<Chord> chords,
  Chord expectChord,
) {
  debugPrint(chords.toString());
  expect(
    chords.singleOrNull,
    equals(expectChord),
  );
}

void _expectMultiFromString(
  Iterable<Chord> chords,
  Iterable<String> expectChords,
) {
  debugPrint(chords.toString());
  expect(
    setEquals(chords.map((e) => e.toString()).toSet(), expectChords.toSet()),
    isTrue,
  );
}
