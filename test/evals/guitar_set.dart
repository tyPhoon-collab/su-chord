import 'package:chord/domains/annotation.dart';
import 'package:chord/domains/estimator/estimator.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
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
    // filter: (path) => path.contains('00_BN1-129-Eb_comp_mic.wav'),
    // filter: (path) => path.contains('01_Rock3-117-Bb_comp_mic.wav'),
    // filter: (path) => path.contains('05_BN1-129-Eb_comp_mic.wav'),
    filter: (path) => path.contains('00_Rock1-130-A_comp_mic.wav'),
  );

  final f = factory4096_0;
  final base = PatternMatchingChordEstimator(
    chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    templateScalar: HarmonicsChromaScalar(until: 6),
  );

  const threshold = 30.0;

  ChordEstimable estimable(String name) => switch (name) {
        'frame' =>
          base.copyWith(chordChangeDetectable: f.hcdf.frame(threshold)),
        'threshold' =>
          base.copyWith(chordChangeDetectable: f.hcdf.threshold(threshold)),
        'cosine' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreThreshold: .9,
            ),
          ),
        'tonal' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreCalculator: const ScoreCalculator.cosine(ToTonalCentroid()),
              scoreThreshold: .9,
            ),
          ),
        'tiv' => base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: threshold,
              scoreCalculator: const ScoreCalculator.cosine(
                ToTonalIntervalVector.musical(),
              ),
              scoreThreshold: .9,
            ),
          ),
        _ => throw UnimplementedError(),
      };

  group('score', () {
    // Table.bypass = true;
    HCDFEvaluator.progressionWriter = null;

    test('HCDF fold', () async {
      await HCDFEvaluator(estimator: estimable('frame'))
          .evaluate(contexts, header: 'fold')
          .toCSV('test/outputs/HCDF/guitar_set_fold.csv');
    });

    test('HCDF threshold', () async {
      await HCDFEvaluator(estimator: estimable('threshold'))
          .evaluate(contexts, header: 'threshold')
          .toCSV('test/outputs/HCDF/guitar_set_threshold.csv');
    });

    test('HCDF cosine', () async {
      await HCDFEvaluator(estimator: estimable('cosine'))
          .evaluate(contexts, header: 'pre frame cosine')
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_cosine.csv');
    });

    test('HCDF tonal', () async {
      await HCDFEvaluator(estimator: estimable('tonal'))
          .evaluate(contexts, header: 'pre frame tonal cosine')
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_tonal_cosine.csv');
    });

    test('HCDF tiv', () async {
      await HCDFEvaluator(estimator: estimable('tiv'))
          .evaluate(contexts, header: 'pre frame TIV cosine')
          .toCSV('test/outputs/HCDF/guitar_set_pre_frame_tiv_cosine.csv');
    });
  });

  group('toy', () {
    final toy = base.copyWith(overridable: _ToyOverride(contexts));
    test('toy score', () async {
      Table.bypass = true;
      HCDFEvaluator.progressionWriter = null;

      await HCDFEvaluator(estimator: toy)
          .evaluate(contexts, header: 'toy')
          .toCSV('test/outputs/HCDF/toy.csv');
    });

    test('toy visualize', () async {
      await HCDFVisualizer(estimator: toy).visualize(
        contexts[0],
      );
    });
  });

  group('function line', () {
    const index = 0;
    const writer = LineChartWriter();
    final chroma = f.guitar
        .reassignment(scalar: MagnitudeScalar.ln)
        .call(contexts[index].data);

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

      await writer(time, score, title: 'guitar set HCDF tonal interval vector');
    });
  });

  group('visualize', () {
    test('all', () async {
      for (final context in contexts) {
        await HCDFVisualizer(estimator: base).visualize(
          context,
          writerContext: LibROSASpecShowContext.of(f.context),
          title: context.outputFileName,
        );
      }
    });

    group('individual', () {
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
          title: 'guitar set tiv',
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
        return context.correct.map((e) => e.time!.toSlice(dt)).toList();
      }
    }

    return null;
  }
}
