import 'package:chord/domains/chroma_calculators/reassignment.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  test('one note', () async {
    final chroma =
        ReassignmentChromaCalculator()(await DataSet().osawa.C3).first;

    debugPrint(chroma.toString());
    expect(chroma.maxIndex, 0);
  });

  test('chord', () async {
    final chroma =
        ReassignmentChromaCalculator()(await DataSet().osawa.C).first;

    expect(chroma.maxIndex, 0);
  });

  test('long duration', () async {
    final chromas = ReassignmentChromaCalculator()(await DataSet().sample);

    expect(chromas, isNotEmpty);
  });

  test('normalized', () async {
    final chromas = ReassignmentChromaCalculator()(await DataSet().G);
    final chroma = chromas[0].l2normalized;

    expect(chroma, isNotNull);
  });
}
