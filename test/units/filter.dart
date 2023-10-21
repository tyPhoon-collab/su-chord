import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/filter.dart';
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

    final c = const AverageFilter(halfRangeIndex: 1).call(chroma);
    expect(c.length, 5);
    expect(c[0].first, (1 + 4) / 2);
    expect(c[1].first, (1 + 4 + 9) / 3);
    expect(c[2].first, (4 + 9 + 16) / 3);
    expect(c[3].first, (9 + 16 + 25) / 3);
    expect(c[4].first, (16 + 25) / 2);
  });
}
