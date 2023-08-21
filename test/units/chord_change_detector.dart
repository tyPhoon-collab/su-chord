import 'package:chord/domains/chord_change_detector.dart';
import 'package:chord/domains/chroma.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('separate chromas', () async {
    final ccd = IntervalChordChangeDetector(interval: 1, dt: 0.25);
    final chromas = List.filled(8, Chroma.empty);
    expect(ccd.reduce(chromas).length, 2);
  });

  test('separate chromas', () async {
    final ccd = IntervalChordChangeDetector(interval: 1, dt: 0.251);
    final chromas = List.filled(8, Chroma.empty);
    expect(ccd.reduce(chromas).length, 1);
  });

  test('separate chromas', () async {
    final ccd = IntervalChordChangeDetector(interval: 1, dt: 0.251);
    final chromas = List.filled(11, Chroma.empty);
    expect(ccd.reduce(chromas).length, 2);
  });
}
