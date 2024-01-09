import 'dart:io';

import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/estimator/search.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/note_extractor.dart';
import 'package:chord/factory.dart';
import 'package:chord/service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';
import '../writer.dart';
import 'evaluator.dart';

Future<void> main() async {
  final contexts = [
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/Halion_CleanGuitarVX',
      const KonokiEADCDelegate(),
    ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/Halion_CleanStratGuitar',
      const KonokiEADCDelegate(),
    ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/HojoGuitar',
      const KonokiEADCDelegate(),
    ),
    ...await EvaluationAudioDataContext.fromFolder(
      'assets/evals/RealStrat',
      const KonokiEADCDelegate(),
    ),
  ];

  Evaluator.progressionWriter = null;

  test('cross validation', () async {
    // Table.bypass = true;
    const folderName = '4 chroma calc 3 estimator';

    final f = f_4096;

    final folderPath =
        'test/outputs/cross_validations/${f.context.sanitize()}/${folderName.sanitize()}';

    final directory = await Directory(folderPath).create(recursive: true);

    logTest('${f.context} $folderPath', title: 'OUTPUT FOLDER PATH');

    for (final estimator in [
      for (final chromaCalculable in [
        for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
          f.guitar.reassignment(scalar: scalar),
          f.guitar.reassignment(scalar: scalar, isReassignFrequency: false),
          f.guitar.stftCombFilter(scalar: scalar),
          f.guitar.reassignCombFilter(scalar: scalar),
        ]
      ]) ...[
        PatternMatchingChordEstimator(
          chromaCalculable: chromaCalculable,
          chordChangeDetectable: f.hcdf.eval,
          // templateScalar: HarmonicsChromaScalar(until: 6),
        ),
        PatternMatchingChordEstimator(
          chromaCalculable: chromaCalculable,
          chordChangeDetectable: f.hcdf.eval,
          context: TemplateContext.harmonicScaling(until: 6),
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
        estimator: estimator,
        validator: (progression) => progression.length == 20,
      ).evaluate(contexts, header: estimator.toString());

      await table.toCSV('${directory.path}/$fileName.csv');
    }
  });

  group('NCSP', () {
    test('summary', () async {
      final factories = [
        f_2048,
        f_4096,
        f_8192,
      ];

      const folderPath = 'test/outputs/cross_validations/NCSP';

      final directory = await Directory(folderPath).create(recursive: true);

      // logTest('${f.context} $folderPath', title: 'OUTPUT FOLDER PATH');

      for (final f in factories) {
        logTest(f.context);

        for (final estimator in [
          for (final chromaCalculable in [
            for (final scalar in [
              MagnitudeScalar.none,
              MagnitudeScalar.ln
            ]) ...[
              f.guitar.stftCombFilter(scalar: scalar),
              f.guitar.reassignment(scalar: scalar, isReassignFrequency: false),
              f.guitar.reassignCombFilter(scalar: scalar),
              f.guitar.reassignment(scalar: scalar),
            ]
          ])
            PatternMatchingChordEstimator(
              chromaCalculable: chromaCalculable,
              chordChangeDetectable: f.hcdf.eval,
              context: TemplateContext.harmonicScaling(until: 6),
            )
        ]) {
          final fileName = estimator.sanitize();

          logTest(estimator);

          final table = Evaluator(
            estimator: estimator,
            validator: (progression) => progression.length == 20,
          ).evaluate(contexts, header: estimator.toString());

          await table
              .toCSV('${directory.path}/${f.context.sanitize()}/$fileName.csv');
        }
      }
    });

    group('paper', () {
      const folderName = 'NCSP_paper';
      final templates = DetectableChords.conv;
      final meanContext = MeanTemplateContext(
        detectableChords: templates,
        meanScalar: const LogChromaScalar(),
        sortedScoreTakeCount: 3,
        scoreThreshold: 0.8,
      );

      //従来法と同じ条件で推定システムのみを変更する
      test('matching vs search', () async {
        final f = f_8192;
        final folderPath =
            'test/outputs/cross_validations/${folderName.sanitize()}';

        final directory = await Directory(folderPath).create(recursive: true);

        final chromaCalculable =
            f.guitar.stftCombFilter(scalar: MagnitudeScalar.ln);

        for (final estimator in [
          SearchTreeChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            detectableChords: templates,
            noteExtractable: switch (chromaCalculable) {
              final HasMagnitudes value =>
                f.extractor.threshold(scalar: value.magnitudeScalar),
              _ => const ThresholdByMaxRatioExtractor(),
            },
            chordSelectable: await f.selector.db,
          ),
          MeanTemplatePatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            chordSelectable: f.selector.flatFive,
            context: meanContext,
          ),
          MeanTemplatePatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            chordSelectable: f.selector.flatFive,
            context:
                // ignore: avoid_redundant_argument_values
                meanContext.copyWith(scalar: HarmonicsChromaScalar(until: 4)),
          ),
          MeanTemplatePatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            chordSelectable: f.selector.flatFive,
            context:
                meanContext.copyWith(scalar: HarmonicsChromaScalar(until: 6)),
          ),
        ]) {
          final fileName = estimator.sanitize();

          logTest(estimator);

          final table = Evaluator(
            estimator: estimator,
            validator: (progression) => progression.length == 20,
          ).evaluate(contexts, header: estimator.toString());

          await table.toCSV('${directory.path}/methods/$fileName.csv');
        }
      });

      test('comb vs et-scale', () async {
        final f = f_8192;
        final folderPath =
            'test/outputs/cross_validations/${folderName.sanitize()}';

        final directory = await Directory(folderPath).create(recursive: true);
        const scalar = MagnitudeScalar.ln;

        for (final estimator in [
          for (final chromaCalculable in [
            f.guitar.stftCombFilter(scalar: scalar),
            f.guitar.reassignment(scalar: scalar, isReassignFrequency: false),
            f.guitar.reassignCombFilter(scalar: scalar),
            f.guitar.reassignment(scalar: scalar),
          ])
            MeanTemplatePatternMatchingChordEstimator(
              chromaCalculable: chromaCalculable,
              chordChangeDetectable: f.hcdf.eval,
              chordSelectable: f.selector.flatFive,
              context:
                  meanContext.copyWith(scalar: HarmonicsChromaScalar(until: 6)),
            ),
        ]) {
          final fileName = estimator.sanitize();

          logTest(estimator);

          final table = Evaluator(
            estimator: estimator,
            validator: (progression) => progression.length == 20,
          ).evaluate(contexts, header: estimator.toString());

          await table.toCSV('${directory.path}/pcp_calculators/$fileName.csv');
        }
      });

      test('window size', () async {
        final folderPath =
            'test/outputs/cross_validations/${folderName.sanitize()}';

        final directory = await Directory(folderPath).create(recursive: true);
        const scalar = MagnitudeScalar.ln;

        for (final f in [
          f_1024,
          f_2048,
          f_4096,
          f_8192,
          f_16384,
        ]) {
          for (final estimator in [
            for (final chromaCalculable in [
              f.guitar.stftCombFilter(scalar: scalar),
              f.guitar.reassignment(scalar: scalar, isReassignFrequency: false),
              f.guitar.reassignCombFilter(scalar: scalar),
              f.guitar.reassignment(scalar: scalar),
            ])
              MeanTemplatePatternMatchingChordEstimator(
                chromaCalculable: chromaCalculable,
                chordChangeDetectable: f.hcdf.eval,
                chordSelectable: f.selector.flatFive,
                context: meanContext.copyWith(
                    scalar: HarmonicsChromaScalar(until: 6)),
              ),
          ]) {
            final fileName = estimator.sanitize();

            logTest(estimator);

            final table = Evaluator(
              estimator: estimator,
              validator: (progression) => progression.length == 20,
            ).evaluate(contexts, header: estimator.toString());

            await table.toCSV(
                '${directory.path}/window_sizes/${f.context.sanitize()}/$fileName.csv');
          }
        }
      });
    });
  });

  test('ICS', () async {
    final factories = [
      f_1024,
      f_2048,
      f_4096,
      f_8192,
      f_16384,
    ];

    const folderPath = 'test/outputs/cross_validations/ICS';

    final directory = await Directory(folderPath).create(recursive: true);

    // logTest('${f.context} $folderPath', title: 'OUTPUT FOLDER PATH');

    for (final f in factories) {
      logTest(f.context);

      for (final estimator in [
        for (final chromaCalculable in [
          for (final scalar in [MagnitudeScalar.none, MagnitudeScalar.ln]) ...[
            f.guitar.stftCombFilter(scalar: scalar),
            f.guitar.reassignment(scalar: scalar, isReassignFrequency: false),
            f.guitar.reassignCombFilter(scalar: scalar),
            f.guitar.reassignment(scalar: scalar),
          ]
        ]) ...[
          SearchTreeChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            chordSelectable: await f.selector.db,
            noteExtractable: switch (chromaCalculable) {
              final HasMagnitudes value =>
                f.extractor.threshold(scalar: value.magnitudeScalar),
              _ => const ThresholdByMaxRatioExtractor(),
            },
          ),
          PatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
          ),
          PatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            // ignore: avoid_redundant_argument_values
            context: TemplateContext.harmonicScaling(until: 4),
          ),
          PatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            context: TemplateContext.harmonicScaling(until: 6),
          ),
        ]
      ]) {
        final fileName = estimator.sanitize();

        logTest(estimator);

        final table = Evaluator(
          estimator: estimator,
          validator: (progression) => progression.length == 20,
        ).evaluate(contexts, header: estimator.toString());

        await table
            .toCSV('${directory.path}/${f.context.sanitize()}/$fileName.csv');
      }
    }
  });

  test('mean template cv', () async {
    // Table.bypass = true;
    final f = f_4096;

    final folderPath =
        'test/outputs/cross_validations/${f.context.sanitize()}/mean_template';

    final directory = await Directory(folderPath).create(recursive: true);

    logTest('${f.context} $folderPath', title: 'OUTPUT FOLDER PATH');

    for (final estimator in [
      for (final chromaCalculable in [
        for (final scalar in [
          MagnitudeScalar.none,
          MagnitudeScalar.ln,
          MagnitudeScalar.dB
        ]) ...[
          f.guitar.reassignment(scalar: scalar),
          f.guitar.reassignment(scalar: scalar, isReassignFrequency: false),
          f.guitar.stftCombFilter(scalar: scalar),
          f.guitar.reassignCombFilter(scalar: scalar),
        ]
      ]) ...[
        MeanTemplatePatternMatchingChordEstimator(
          chromaCalculable: chromaCalculable,
          chordChangeDetectable: f.hcdf.eval,
          chordSelectable: f.selector.flatFive,
          context: MeanTemplateContext.harmonicScaling(until: 6),
        ),
        SearchTreeChordEstimator(
          chromaCalculable: chromaCalculable,
          chordChangeDetectable: f.hcdf.eval,
          chordSelectable: await f.selector.db,
          noteExtractable: switch (chromaCalculable) {
            final HasMagnitudes value =>
              f.extractor.threshold(scalar: value.magnitudeScalar),
            _ => const ThresholdByMaxRatioExtractor(),
          },
        ),
      ]
    ]) {
      final fileName = estimator.sanitize();

      logTest(estimator);

      final table = Evaluator(
        estimator: estimator,
        validator: (progression) => progression.length == 20,
      ).evaluate(contexts, header: estimator.toString());

      await table.toCSV('${directory.path}/$fileName.csv');
    }
  });

  test('window function', () async {
    const folderPath = 'test/outputs/cross_validations/window_function';

    final directory = await Directory(folderPath).create(recursive: true);
    const scalar = MagnitudeScalar.ln;

    for (final f in [
      f_1024,
      f_2048,
      f_4096,
      f_8192,
      f_16384,
      f_1024.copyWith(windowFunction: NamedWindowFunction.blackman),
      f_2048.copyWith(windowFunction: NamedWindowFunction.blackman),
      f_4096.copyWith(windowFunction: NamedWindowFunction.blackman),
      f_8192.copyWith(windowFunction: NamedWindowFunction.blackman),
      f_16384.copyWith(windowFunction: NamedWindowFunction.blackman),
    ]) {
      for (final estimator in [
        for (final chromaCalculable in [
          f.guitar.stftCombFilter(scalar: scalar),
          f.guitar.reassignment(
            scalar: scalar,
            isReassignFrequency: false,
          ),
          f.guitar.reassignCombFilter(scalar: scalar),
          f.guitar.reassignment(scalar: scalar),
        ])
          MeanTemplatePatternMatchingChordEstimator(
            chromaCalculable: chromaCalculable,
            chordChangeDetectable: f.hcdf.eval,
            chordSelectable: f.selector.flatFive,
            context: MeanTemplateContext.harmonicScaling(
              until: 6,
              detectableChords: DetectableChords.conv,
              meanScalar: const LogChromaScalar(),
              sortedScoreTakeCount: 3,
              scoreThreshold: 0.8,
            ),
          ),
      ]) {
        final fileName = estimator.sanitize();

        logTest(estimator);

        final table = Evaluator(
          estimator: estimator,
          validator: (progression) => progression.length == 20,
        ).evaluate(contexts, header: estimator.toString());

        await table
            .toCSV('${directory.path}/${f.context.sanitize()}/$fileName.csv');
      }
    }
  });
}
