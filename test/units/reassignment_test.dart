import 'package:chord/factory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  final f = f_8192;
  final calculate = f.guitar.reassignment();

  test('one note', () async {
    final chroma = calculate(await DataSet().osawa.C3).first;

    debugPrint(chroma.toString());
    expect(chroma.maxIndex, 0);
  });

  test('chord', () async {
    final chroma = calculate(await DataSet().osawa.C).first;

    expect(chroma.maxIndex, 0);
  });

  test('long duration', () async {
    final chromas = calculate(await DataSet().sample);

    expect(chromas, isNotEmpty);
  });

  test('normalized', () async {
    final chromas = calculate(await DataSet().G);
    final chroma = chromas[0].l2normalized;

    expect(chroma, isNotNull);
  });
}
