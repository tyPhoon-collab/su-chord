import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/formula.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  // test('threshold', () {
  //   final chroma = [
  //     Chroma(const [1, 1, 1]),
  //     Chroma(const [10, 10, 10]),
  //     Chroma(const [100, 100, 100]),
  //   ];
  //
  //   final c = const ThresholdFilter(threshold: 10).call(chroma);
  //   expect(c.length, 2);
  // });

  test('average', () {
    final chroma = List.generate(5, (index) => 1 + index.toDouble())
        .map((e) => Chroma(List.filled(3, e * e)))
        .toList();

    final c = const AverageFilter(kernelRadius: 1).call(chroma);
    expect(c.length, 5);
    expect(c[0].first, (1 + 4) / 2);
    expect(c[1].first, (1 + 4 + 9) / 3);
    expect(c[2].first, (4 + 9 + 16) / 3);
    expect(c[3].first, (9 + 16 + 25) / 3);
    expect(c[4].first, (16 + 25) / 2);
  });

  group('gaussian', () {
    test('normal', () {
      final chroma = List.generate(5, (index) => 1 + index.toDouble())
          .map((e) => Chroma(List.filled(3, e * e)))
          .toList();

      final c = GaussianFilter(stdDevIndex: 1, kernelRadius: 3).call(chroma);
      expect(c.length, 5);

      final cls = normalDistributionClosure(0, 1);
      expect(
        c[0].first,
        cls(0) * 1 + cls(1) * 4 + cls(2) * 9 + cls(3) * 16,
      );

      expect(
        c[1].first,
        cls(-1) * 1 + cls(0) * 4 + cls(1) * 9 + cls(2) * 16 + cls(3) * 25,
      );

      expect(
        c[4].first,
        cls(-3) * 4 + cls(-2) * 9 + cls(-1) * 16 + cls(0) * 25,
      );
    });

    test('delta time', () {
      final chroma = List.generate(5, (index) => 1 + index.toDouble())
          .map((e) => Chroma(List.filled(3, e * e)))
          .toList();

      final c = GaussianFilter.dt(stdDev: 0.1, dt: 0.1).call(chroma);
      expect(c.length, 5);

      final cls = normalDistributionClosure(0, 1);
      expect(
        c[0].first,
        cls(0) * 1 + cls(1) * 4 + cls(2) * 9 + cls(3) * 16,
      );

      expect(
        c[1].first,
        cls(-1) * 1 + cls(0) * 4 + cls(1) * 9 + cls(2) * 16 + cls(3) * 25,
      );

      expect(
        c[4].first,
        cls(-3) * 4 + cls(-2) * 9 + cls(-1) * 16 + cls(0) * 25,
      );
    });

    test('delta time 2', () {
      final chroma = List.generate(5, (index) => 1 + index.toDouble())
          .map((e) => Chroma(List.filled(3, e * e)))
          .toList();

      final c = GaussianFilter.dt(stdDev: 0.2, dt: 0.1).call(chroma);
      expect(c.length, 5);

      final cls = normalDistributionClosure(0, 2);
      expect(
        c[0].first,
        cls(0) * 1 + cls(1) * 4 + cls(2) * 9 + cls(3) * 16 + cls(4) * 25,
      );

      expect(
        c[1].first,
        cls(-1) * 1 + cls(0) * 4 + cls(1) * 9 + cls(2) * 16 + cls(3) * 25,
      );

      expect(
        c[4].first,
        cls(-4) * 1 + cls(-3) * 4 + cls(-2) * 9 + cls(-1) * 16 + cls(0) * 25,
      );
    });
  });

  test('compression', () {
    final chroma = [
      Chroma(const [1, 2, 3]),
      Chroma(const [10, 20, 30]),
      Chroma(const [100, 200, 300]),
    ];

    final c = const CompressionFilter().call(chroma);

    expect(c[0].max, 2);
    expect(c[1].max, 20);
    expect(c[2].max, 200);
  });

  //処理系によって用いるべき閾値は異なる
  //調査するための関数
  test('threshold checker', () async {
    final f = f_4096;
    final cc = [
      // f.guitar.reassignment(), // about 100
      // f.guitar.reassignment(scalar: MagnitudeScalar.ln), // about 30
      f.guitar.reassignCombFilter(), // about 10
      // f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln), // about 3
      // f.guitar.stftCombFilter(), // about 8
      // f.guitar.stftCombFilter(scalar: MagnitudeScalar.ln), // about 2
    ].first;

    debugPrint(cc.toString());

    final chromas = cc.call(await DataSet().G_Em_Bm_C);

    final powers = chromas.map((e) => e.l2norm);
    debugPrint(powers.toList().toString());
  });
}
