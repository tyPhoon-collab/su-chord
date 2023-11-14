import 'dart:io';

import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/estimator/search.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/note_extractor.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';
import '../writer.dart';
import 'evalulator.dart';

void main() {
  late final Iterable<EvaluationAudioDataContext> contexts;

  setUpAll(() async {
    // 使用する音源はフォルダごとに管理されている
    contexts = [
      ...await EvaluationAudioDataContext.fromFolder(
          'assets/evals/Halion_CleanGuitarVX'),
      ...await EvaluationAudioDataContext.fromFolder(
          'assets/evals/Halion_CleanStratGuitar'),
      ...await EvaluationAudioDataContext.fromFolder('assets/evals/HojoGuitar'),
      ...await EvaluationAudioDataContext.fromFolder('assets/evals/RealStrat'),
    ];
  });

  test('cross validation', () async {
    Table.bypass = false; //交差検証は目で見てもわからないので、からなず書き込む

    const folderName = 'temp';

    final f = factory4096_0;

    final folderPath =
        'test/outputs/cross_validations/${f.context.sanitize()}/${folderName.sanitize()}';

    final directory = await Directory(folderPath).create(recursive: true);

    logTest('${f.context} $folderPath');

    for (final estimator in [
      for (final chromaCalculable in [
        for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
          f.guitar.reassignment(scalar: scalar),
          f.guitar.stftCombFilter(scalar: scalar),
          f.guitar.reassignCombFilter(scalar: scalar),
        ]
      ]) ...[
        PatternMatchingChordEstimator(
          chromaCalculable: chromaCalculable,
          chordChangeDetectable: f.hcdf.eval,
          // templateScalar: HarmonicsChromaScalar(until: 6),
        ),
        SearchTreeChordEstimator(
          chromaCalculable: chromaCalculable,
          chordChangeDetectable: f.hcdf.eval,
          noteExtractable: switch (chromaCalculable) {
            final HasMagnitudes value =>
              f.extractor.threshold(scalar: value.magnitudeScalar),
            _ => const ThresholdByMaxRatioExtractor(),
          },
          chordSelectable: await f.selector.db,
        ),
      ]
    ]) {
      final fileName = estimator.sanitize();

      logTest(estimator);

      final table = Evaluator(
        header: [estimator.toString()],
        estimator: estimator,
        validator: (progression) => progression.length == 20,
      ).evaluate(contexts);

      table.toCSV('${directory.path}/$fileName.csv');
    }
  });
}
