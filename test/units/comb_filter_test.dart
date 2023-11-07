import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import '../data_set.dart';

void main() {
  test('one note', () async {
    final chroma =
        CombFilterChromaCalculator(magnitudesCalculable: MagnitudesCalculator())
            .call(await DataSet().osawa.C3)
            .first;

    debugPrint(chroma.toString());
    expect(chroma.maxIndex, 0);
  });

  test('chord', () async {
    final chroma =
        CombFilterChromaCalculator(magnitudesCalculable: MagnitudesCalculator())
            .call(await DataSet().osawa.C)
            .first;

    expect(chroma, isNotNull);
  });

  test('std dev coef', () async {
    final f = factory8192_0;
    const contexts = [
      CombFilterContext(hzStdDevCoefficient: 1 / 24),
      CombFilterContext(hzStdDevCoefficient: 1 / 48),
// ignore: avoid_redundant_argument_values
      CombFilterContext(hzStdDevCoefficient: 1 / 72),
      CombFilterContext(hzStdDevCoefficient: 1 / 96),
    ];

    for (final c in contexts) {
      final chroma = f.filter
          .interval(4.seconds)(
            CombFilterChromaCalculator(
              magnitudesCalculable: f.magnitude.stft(),
              context: c,
            ).call(await DataSet().G),
          )
          .first
          .l2normalized;

      debugPrint(chroma.toString());
    }
  });

  test('log vs normal', () async {
    final filter = factory8192_0.filter.interval(4.seconds);
    final data = await DataSet().G;

    debugPrint(filter(
      factory8192_0.big.combFilter().call(data),
    ).first.l2normalized.toString());

    debugPrint(filter(
      factory8192_0.big.stftCombFilter(scalar: MagnitudeScalar.ln).call(data),
    ).first.l2normalized.toString());
  });

  test('guitar tuning', () async {
    final ccd = factory8192_0.filter.interval(3.seconds);
    final chromas =
        ccd(factory8192_0.guitar.combFilter().call(await DataSet().G));

    expect(chromas[0], isNotNull);
  });
}