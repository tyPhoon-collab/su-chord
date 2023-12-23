import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimator/estimator.dart';
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

class MeanScoreSpotComparator {
  const MeanScoreSpotComparator({
    required this.chromaCalculable,
    this.scalar,
  });

  final ChromaCalculable chromaCalculable;
  final ChromaMappable? scalar;

  Chroma _getTemplate(Note note) {
    final chords = ChromaChordEstimator.defaultDetectableChords
        .where((e) => e.root == note);
    final pcp = chords
        .map((e) => scalar?.call(e.unitPCP) ?? e.unitPCP)
        .cast<Chroma>()
        .reduce((value, element) => value + element);

    return pcp;
  }

  Future<void> call({
    required String source,
    required final int index,
  }) async {
    final data = await SimpleAudioLoader(path: source).load(sampleRate: 22050);

    final pcp =
        average(chromaCalculable.call(data.cutEvaluationAudioByIndex(index)))
            .first;

    const scoreCalculator = ScoreCalculator.cosine();

    for (final note in Note.sharpNotes) {
      final template = _getTemplate(note);

      logTest('$note group\t: ${scoreCalculator(pcp, template)}');
    }
  }
}
