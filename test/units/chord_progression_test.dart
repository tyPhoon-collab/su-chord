import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chord_progression.dart';
import 'package:chord/utils/loaders/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
