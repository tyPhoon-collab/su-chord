import 'package:chord/domains/estimator.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

void main() {
  group('stream', () {
    test('22050 chunk size', () async {
      final e = PatternMatchingChordEstimator(
        chromaCalculable: factory2048_1024.guitarRange.reassignment,
        filters: factory2048_1024.filter.eval,
      );
      final data = await AudioLoader.sample.load(
        duration: 21,
        sampleRate: factory2048_1024.context.sampleRate,
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
      chromaCalculable: factory2048_1024.guitarRange.reassignment,
      filters: factory2048_1024.filter.eval,
    );

    final data = await AudioLoader.sample.load();
    final chords = e.estimate(data);

    expect(chords.length, 20);
  });

  test('pattern matching scalar', () async {
    final e = PatternMatchingChordEstimator(
      chromaCalculable: factory2048_1024.guitarRange.reassignment,
      filters: factory2048_1024.filter.eval,
      chordSelectable: await factory2048_1024.selector.db,
      scalar: TemplateChromaScalar.thirdHarmonic(0.1),
    );

    final data = await AudioLoader.sample.load();
    final chords = e.estimate(data);

    expect(chords.length, 20);
  });
}
