import 'package:chord/domains/estimate.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loader.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

final factory = EstimatorFactory(const FactoryContext(
  chunkSize: 2048,
  chunkStride: 1024,
  sampleRate: 22050,
));

void main() {
  group('stream', () {
    test('22050 chunk size', () async {
      final e = PatternMatchingChordEstimator(
        chromaCalculable: factory.guitarRange.reassignment,
        filters: factory.filter.eval,
      );
      final data = await AudioLoader.sample.load(
        duration: 21,
        sampleRate: factory.context.sampleRate,
      );
      await for (final chords in const AudioStreamEmulator()
          .stream(data)
          .map((data) => e.estimate(data, false))) {
        debugPrint(chords.toString());
      }
      debugPrint(e.flush().toString());
    });
  });

  test('reassignment chroma chord estimate', () async {
    final e = PatternMatchingChordEstimator(
      chromaCalculable: factory.guitarRange.reassignment,
      filters: factory.filter.eval,
    );

    final data = await AudioLoader.sample.load();
    final chords = e.estimate(data);

    expect(chords.length, 20);
  });
}
