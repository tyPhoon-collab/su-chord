import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:chord/utils/score.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';

void main() {
  group('parse', () {
    test('degree chord', () async {
      final csv = await CSVLoader.db.load();
      final chords = csv.map((e) {
        final row = e.whereType<String>().toList();
        return ChordProgression.fromDegreeChordRow(row);
      });
      debugPrint(chords.toString());
    });
  });

  group('simplify', () {
    final chordRow = ['C', 'C', 'G', 'Am', 'Am', 'Am', 'Em', 'Em7'];

    test('label', () {
      final progression = ChordProgression.fromChordRow(chordRow);

      final simple = progression.simplify();
      debugPrint(progression.toString());
      debugPrint(simple.toString());
      expect(simple.length, 5);
    });

    test('time', () {
      final progression = ChordProgression.fromChordRow(
        chordRow,
        times: List.generate(chordRow.length, (i) => Time(i.toDouble(), i + 1)),
      );

      final simple = progression.simplify();
      debugPrint(progression.toDetailString());
      debugPrint(simple.toDetailString());
      expect(simple.length, 5);
    });
  });

  group('overlap score', () {
    final correct = ChordProgression.fromChordRow(
      const ['C', 'Am', 'F', 'G'],
      times: const [
        Time(0, 2),
        Time(2, 4),
        Time(5, 8),
        Time(10, 20),
      ],
    );
    test('perfect', () {
      final f = correct.overlapScore(correct);

      logTest(f);
      expect(f, FScore(17, 0, 0));
    });

    test('less', () {
      final f = correct.overlapScore(ChordProgression.fromChordRow(
        const ['C', 'F', 'G'],
        times: const [Time(0, 4), Time(5, 8), Time(10, 20)],
      ));

      logTest(f);
      expect(f, FScore(15, 2, 0));
    });

    test('more', () {
      final f = correct.overlapScore(ChordProgression.fromChordRow(
        const ['C', 'Am', 'F', 'G', 'GM7'],
        times: const [
          Time(0, 2),
          Time(2, 4),
          Time(5, 8),
          Time(10, 13),
          Time(13, 20)
        ],
      ));

      logTest(f);
      expect(f, FScore(10, 7, 0));
    });

    test('false positive', () {
      final f = correct.overlapScore(ChordProgression.fromChordRow(
        const ['C', 'Am', 'F', 'G'],
        times: const [Time(0, 2), Time(2, 5), Time(5, 8), Time(9, 20)],
      ));

      logTest(f);
      expect(f, FScore(17, 2, 0));
    });

    test('false negative', () {
      final f = correct.overlapScore(ChordProgression.fromChordRow(
        const ['C', 'Am', 'F', 'G'],
        times: const [Time(0, 2), Time(2, 4), Time(5, 8), Time(10, 18)],
      ));

      logTest(f);
      expect(f, FScore(15, 0, 2));
    });
  });
}
