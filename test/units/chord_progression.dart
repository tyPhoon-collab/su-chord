import 'package:chord/domains/chord_progression.dart';
import 'package:chord/utils/loader/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parse', () {
    test('degree chord', () async {
      final csv = await CSVLoader.db.load();
      final chords = csv.map((e) {
        final row = e.whereType<String>().toList();
        return DegreeChordProgression.fromCSVRow(row);
      });
      debugPrint(chords.toString());
    });
  });
}
