import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/factory.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  final f = factory8192_0;
  final calculate = f.guitar.combFilter();

  test('one note', () async {
    final chroma = calculate(await DataSet().osawa.C3).first;

    debugPrint(chroma.toString());
    expect(chroma.maxIndex, 0);
  });

  test('chord', () async {
    final chroma = calculate(await DataSet().osawa.C).first;

    expect(chroma, isNotNull);
  });

  test('std dev coef', () async {
    const contexts = [
      CombFilterContext(hzStdDevCoefficient: 1 / 24),
      CombFilterContext(hzStdDevCoefficient: 1 / 48),
// ignore: avoid_redundant_argument_values
      CombFilterContext(hzStdDevCoefficient: 1 / 72),
      CombFilterContext(hzStdDevCoefficient: 1 / 96),
    ];

    for (final c in contexts) {
      final chroma = average(
        f.guitar.combFilter(combFilterContext: c).call(await DataSet().G),
      ).first.l2normalized;

      debugPrint(chroma.toString());
    }
  });

  test('log vs normal', () async {
    final data = await DataSet().G;

    debugPrint(average(
      f.big.combFilter().call(data),
    ).first.l2normalized.toString());

    debugPrint(average(
      f.big.stftCombFilter(scalar: MagnitudeScalar.ln).call(data),
    ).first.l2normalized.toString());
  });

  test('guitar tuning', () async {
    final chromas = average(calculate(await DataSet().G));

    expect(chromas[0], isNotNull);
  });
}
