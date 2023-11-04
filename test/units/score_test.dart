import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('mapper', () {
    test('tonal centroid', () {
      final pcp = PCP(const [0, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0]);
      final tc = const ToTonalCentroid().call(pcp);
      debugPrint(tc.toString());
    });
  });

  group('metrics', () {
    test('cosine similarity', () async {
      final c1 = Chroma(const [1, 1, 1, 1]);
      expect(const CosineSimilarity().call(c1, c1), 1);

      final c2 = Chroma(const [-1, -1, -1, -1]);
      expect(const CosineSimilarity().call(c1, c2), -1);
    });
  });
}
