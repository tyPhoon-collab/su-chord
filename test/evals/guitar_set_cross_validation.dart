import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:flutter_test/flutter_test.dart';

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
  // final base = PatternMatchingChordEstimator(
  final base = MeanTemplatePatternMatchingChordEstimator(
    chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
    context: MeanTemplateContext.harmonicScaling(until: 6, scoreThreshold: 0.8),
  );

  HCDFEvaluator.progressionWriter = null;

  test('cross validation', () async {
    for (final scoreThreshold in const [.75, .8, .85, .9]) {
      logTest(scoreThreshold, title: 'Threshold');

      for (final scoreCalculator in const [
        ScoreCalculator.cosine(),
        ScoreCalculator.cosine(ToTonalCentroid()),
        ScoreCalculator.cosine(ToTonalIntervalVector.musical()),
      ]) {
        logTest(scoreCalculator, title: 'Calculator');
        HCDFEvaluator(
          estimator: base.copyWith(
            chordChangeDetectable: f.hcdf.preFrameCheck(
              powerThreshold: 15,
              scoreCalculator: scoreCalculator,
              scoreThreshold: scoreThreshold,
            ),
          ),
        ).evaluate(contexts);
      }
    }
  });
}
