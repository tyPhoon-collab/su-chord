import 'package:chord/domains/chord_search_tree.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/estimator/search.dart';
import 'package:chord/factory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../util.dart';

void main() {
  final f = f_4096;
  final estimator = PatternMatchingChordEstimator(
    chromaCalculable: f.guitar.reassignment(),
    chordChangeDetectable: f.hcdf.eval,
    context: Template(DetectableChords.conv),
  );

  test('reassignment', () async {
    final chords = estimator.estimate(await DataSet().sample);

    expect(chords.length, 20);
  });

  test('search tree', () async {
    final e = SearchTreeChordEstimator(
      chromaCalculable: f.guitar.reassignment(),
      chordChangeDetectable: f.hcdf.eval,
      chordSelectable: await f.selector.db,
      context: Possible(DetectableChords.frontend),
    );

    final chords = e.estimate(await DataSet().sample);

    expect(chords.length, 20);
  });

  group('stream', () {
    test(
      '22050 chunk size',
      () async {
        await for (final chords in const AudioStreamEmulator()
            .stream(await DataSet().G_Em_Bm_C)
            .map((data) => estimator.estimate(data, false))) {
          debugPrint(chords.toString());
        }
        debugPrint(estimator.flush().toString());
      },
      tags: 'simulation',
    );
  });
}
