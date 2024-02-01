import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord_cell.dart';
import 'package:chord/utils/score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('score', () {
    final correct = ChordCell(chord: Chord.C, time: const Time(3, 5));

    group('same', () {
      test('perfect', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.C,
            time: const Time(3, 5),
          )),
          FScore.one(2),
        );
      });
      test('perfect fast half', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.C,
            time: const Time(3, 4),
          )),
          FScore(1, 0, 1),
        );
      });
      test('perfect late half', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.C,
            time: const Time(4, 5),
          )),
          FScore(1, 0, 1),
        );
      });
      test('slide 1 sec fast', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.C,
            time: const Time(2, 4),
          )),
          FScore(1, 1, 1),
        );
      });
      test('slide 1 sec late', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.C,
            time: const Time(4, 6),
          )),
          FScore(1, 1, 1),
        );
      });
    });

    group('different', () {
      test('time', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.C,
            time: const Time(1, 2),
          )),
          FScore.zero,
        );
      });
      test('chord', () {
        expect(
          correct.overlapScore(ChordCell(
            chord: Chord.D,
            time: const Time(3, 5),
          )),
          FScore(0, 2, 0),
        );
      });
    });

    test('limitation', () {
      expect(
        correct.overlapScore(
          ChordCell(
            chord: Chord.C,
            time: const Time(3, 5),
          ),
          limitation: const Time(3, 4),
        ),
        FScore.one(1),
      );
    });
  });

  group('transpose', () {
    test('base +2', () {
      expect(
        ChordCell(chord: Chord.C).transpose(2),
        ChordCell(chord: Chord.D),
      );
    });

    test('multi +2', () {
      expect(
        MultiChordCell(chord: Chord.C).transpose(2),
        MultiChordCell(chord: Chord.D),
      );

      expect(
        MultiChordCell.first([Chord.C]).transpose(2),
        MultiChordCell.first([Chord.D]),
      );
    });
  });
}
