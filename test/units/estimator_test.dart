import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/estimator/search.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../util.dart';

void main() {
  final f = factory2048_1024;

  test('reassignment', () async {
    final e = PatternMatchingChordEstimator(
      chromaCalculable: f.guitarRange.reassignment(),
      filters: f.filter.eval,
    );

    final chords = e.estimate(await DataSet().sample);

    expect(chords.length, 20);
  });

  test('search tree', () async {
    final e = SearchTreeChordEstimator(
      chromaCalculable: f.guitarRange.reassignment(),
      filters: f.filter.eval,
      chordSelectable: await f.selector.db,
    );

    final chords = e.estimate(await DataSet().sample);

    expect(chords.length, 20);
  });

  test('from notes', () async {
    final e = FromNotesChordEstimator(
      chromaCalculable: f.guitarRange.reassignCombFilter(),
      filters: f.filter.eval,
    );

    final chords = e.estimate(await DataSet().sample);

    expect(chords.length, 20);
  });

  group('stream', () {
    test('22050 chunk size', () async {
      final e = PatternMatchingChordEstimator(
        chromaCalculable: factory2048_1024.guitarRange.reassignment(),
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
}
