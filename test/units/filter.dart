import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/utils/formula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('threshold', () {
    final chroma = [
      Chroma(const [1, 1, 1]),
      Chroma(const [10, 10, 10]),
      Chroma(const [100, 100, 100]),
    ];

    final c = const ThresholdFilter(threshold: 10).call(chroma);
    expect(c.length, 2);
  });

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
}
