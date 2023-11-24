import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';

import '../data_set.dart';
import '../writer.dart';

class SpotComparator {
  const SpotComparator({
    required this.chromaCalculable,
    this.writer,
  });

  final ChromaCalculable chromaCalculable;
  final PCPChartWriter? writer;

  Future<void> call({
    required String source,
    required final int index,
    required final Iterable<Chord> chords,
  }) async {
    final data = await SimpleAudioLoader(path: source).load(sampleRate: 22050);

    final pcp =
        average(chromaCalculable(data.cutEvaluationAudioByIndex(index))).first;

    writer?.call(pcp.l2normalized);

    for (final chord in chords) {
      final template =
          HarmonicsChromaScalar(until: 6).call(chord.unitPCP).l2normalized;

      // writer(template);

      final score = const ScoreCalculator.cosine().call(pcp, template);

      logTest('$chord: $score');
    }
  }
}
