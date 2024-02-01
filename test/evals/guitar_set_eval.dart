import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/service.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';
import '../writer.dart';
import 'evaluator.dart';

Future<void> main() async {
  final contexts = await EvaluationAudioDataContext.fromFolder(
    'assets/evals/3371780/audio_mono-mic',
    const GuitarSetEADCDelegate(),
    // filter: (path) => path.contains('comp'),
    filter: (path) => path.contains('comp') && path.contains('SS'),
    // filter: (path) => path.contains('00_BN1-129-Eb_comp_mic.wav'),
    // filter: (path) => path.contains('01_Rock3-117-Bb_comp_mic.wav'),
    // filter: (path) => path.contains('05_BN1-129-Eb_comp_mic.wav'),
    // filter: (path) => path.contains('00_Rock1-130-A_comp_mic.wav'),
    // filter: (path) => path.contains('00_Funk1-114-Ab_comp_mic.wav'),
    // filter: (path) => path.contains('05_SS3-98-C_comp_mic.wav'),
    // filter: (path) => path.contains('01_SS1-100-C#_comp_mic.wav'),
    // filter: (path) => path.contains('00_SS3-84-Bb_comp_mic.wav'),
  );

  final f = f_4096.copyWith(chunkStride: 2048);

  final base = MeanTemplatePatternMatchingChordEstimator(
    chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    scoreThreshold: 0.8,
    context: LnMeanTemplate.overtoneBy6th(DetectableChords.conv),
  );

  const threshold = 15.0;

  ChordEstimable estimable(String name, [double scoreThreshold = .8]) =>
      switch (name) {
        'frame' =>
          base.copyWith(chordChangeDetectable: f.hcdf.frame(threshold)),
        'threshold' =>
          base.copyWith(chordChangeDetectable: f.hcdf.threshold(threshold)),
        'cosine' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreThreshold: scoreThreshold,
            ),
          ),
        'tonal' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
              scoreThreshold: scoreThreshold,
            ),
          ),
        'tiv' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreCalculator: const ScoreCalculator.cosine(
                ToTonalIntervalVector.musical(),
              ),
              scoreThreshold: scoreThreshold,
            ),
          ),
        _ => throw UnimplementedError(),
      };

  group('score', () {
    // Table.bypass = true;
    HCDFEvaluator.progressionWriter = null;

    test('HCDF fold', () async {
      await HCDFEvaluator(estimator: estimable('frame'))
          .evaluate(contexts)
          .toCSV('test/outputs/HCDF/guitar_set_fold.csv');
    });

    test('HCDF threshold', () async {
      await HCDFEvaluator(estimator: estimable('threshold'))
          .evaluate(contexts)
          .toCSV('test/outputs/HCDF/guitar_set_threshold.csv');
    });

    test('HCDF cosine', () async {
      await HCDFEvaluator(estimator: estimable('cosine'))
          .evaluate(contexts)
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_cosine.csv');
    });

    test('HCDF tonal', () async {
      await HCDFEvaluator(estimator: estimable('tonal'))
          .evaluate(contexts)
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_tonal_cosine.csv');
    });

    test('HCDF tiv', () async {
      await HCDFEvaluator(estimator: estimable('tiv'))
          .evaluate(contexts)
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_tiv_cosine.csv');
    });
  });

  group('toy', () {
    final toy = base.copyWith(overridable: _ToyOverride(contexts));

    test('toy score', () async {
      // Table.bypass = true;
      HCDFEvaluator.progressionWriter = null;

      await HCDFEvaluator(estimator: toy)
          .evaluate(contexts)
          .toCSV('test/outputs/HCDF/guitar_set_toy.csv');
    });

    group('toy visualize', () {
      test('toy all', () async {
        for (final context in contexts) {
          await HCDFVisualizer(estimator: toy).visualize(
            context,
            writerContext: LibROSASpecShowContext.of(f.context),
            title: context.outputFileName,
          );
        }
      });
      test('toy part', () async {
        await HCDFVisualizer(estimator: toy).visualize(
          contexts[0],
        );
      });
    });
  });

  group('function line', () {
    const writer = LineChartWriter();

    test('fl all', () async {
      List<Chroma> cc(AudioData data) {
        // final filter = GaussianFilter.dt(stdDev: 0.1, dt: f.context.deltaTime);
        List<Chroma> filter(e) => e;

        return filter(
          f.guitar.reassignment(scalar: MagnitudeScalar.ln).call(data),
        );
      }

      Future<void> write(List<Chroma> chroma, String title) async {
        const scoreCalculator =
            ScoreCalculator.cosine(ToTonalIntervalVector.musical());

        final (time, score) = getTimeAndScore(
          f.context.deltaTime,
          chroma,
          scoreCalculator,
          nanTo: 1,
        );

        await writer(time, score, title: title);
      }

      await Future.wait(
        contexts.map(
          (context) => write(
            cc(context.data),
            'guitar_set_HCDF_${context.outputFileName}',
          ),
        ),
      );
    });

    group('fl individual', () {
      const index = 0;

      final filter = GaussianFilter.dt(stdDev: 0.1, dt: f.context.deltaTime);
      // List<Chroma> filter(e) => e;

      final chroma = filter(
        f.guitar
            .reassignment(scalar: MagnitudeScalar.ln)
            .call(contexts[index].data),
      );

      test('line cosine', () async {
        const scoreCalculator = ScoreCalculator.cosine();
        final (time, score) = getTimeAndScore(
          f.context.deltaTime,
          chroma,
          scoreCalculator,
          mapper: (e) => e == 0 ? 1 : e,
        );

        await writer(time, score, title: 'guitar set HCDF cosine similarity');
      });

      test('line tonal', () async {
        const scoreCalculator = ScoreCalculator.cosine(ToTonalCentroid());
        final (time, score) = getTimeAndScore(
          f.context.deltaTime,
          chroma,
          scoreCalculator,
          nanTo: 1,
        );

        await writer(time, score, title: 'guitar set HCDF tonal centroid');
      });

      test('line tiv', () async {
        const scoreCalculator =
            ScoreCalculator.cosine(ToTonalIntervalVector.musical());

        final (time, score) = getTimeAndScore(
          f.context.deltaTime,
          chroma,
          scoreCalculator,
          nanTo: 1,
        );

        await writer(time, score,
            title: 'guitar set HCDF tonal interval vector');
      });
    });
  });

  group('visualize', () {
    Table.bypass = false;
    test('v all', () async {
      await Future.wait(contexts.map((context) => HCDFVisualizer(
            estimator: estimable('tiv', 0.85),
            simplify: false,
          ).visualize(
            context,
            writerContext: LibROSASpecShowContext.of(f.context),
            title: context.outputFileName,
          )));
    });

    group('v individual', () {
      const index = 0;

      test('v fold', () async {
        await HCDFVisualizer(estimator: estimable('frame')).visualize(
          contexts[index],
          title: 'guitar set frame',
        );
      });

      test('v threshold', () async {
        await HCDFVisualizer(estimator: estimable('threshold')).visualize(
          contexts[index],
          title: 'guitar set threshold',
        );
      });

      test('v cosine', () async {
        await HCDFVisualizer(estimator: estimable('cosine')).visualize(
          contexts[index],
          title: 'guitar set cosine',
        );
      });

      test('v tonal', () async {
        await HCDFVisualizer(estimator: estimable('tonal')).visualize(
          contexts[index],
          title: 'guitar set tonal',
        );
      });

      test('v tiv', () async {
        await HCDFVisualizer(estimator: estimable('tiv')).visualize(
          contexts[index],
          // title: 'guitar set tiv',
        );
      });
    });
  });
}

final class _ToyOverride implements ChromaChordEstimatorOverridable {
  const _ToyOverride(this.contexts);

  final List<EvaluationAudioDataContext> contexts;

  @override
  List<Slice>? slices(ChromaChordEstimator estimator, AudioData audioData) {
    if (audioData.path == null) return null;

    for (final context in contexts) {
      if (audioData.path!.contains(context.musicName)) {
        final dt = estimator.chromaCalculable.deltaTime(audioData.sampleRate);
        final slices = context.correct.map((e) => e.time!.toSlice(dt)).toList();
        return slices;
      }
    }

    return null;
  }
}
