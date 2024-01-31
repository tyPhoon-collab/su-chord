import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/service.dart';
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
        chromaCalculable(data.cutEvaluationAudioByIndex(index)).average().first;

    await writer?.call(pcp.l2normalized);

    for (final chord in chords) {
      final template = PCP.harmonicTemplate(chord, until: 6);
      // writer(template);

      final score = const ScoreCalculator.cosine().call(pcp, template);

      logTest('$chord: $score');
    }
  }
}

class MeanScoreSpotComparator {
  MeanScoreSpotComparator({
    required this.chromaCalculable,
    this.scalar,
    this.meanScalar,
  }) : loader = CacheableAudioLoader(sampleRate: 22050);

  final ChromaCalculable chromaCalculable;
  final ChromaMappable? scalar;
  final ChromaMappable? meanScalar;
  final CacheableAudioLoader loader;

  Chroma _buildTemplate(Note note) => PCP.meanTemplate(MeanTemplateContext(
        scalar: scalar,
        meanScalar: meanScalar,
        detectableChords:
            DetectableChords.frontend.where((e) => e.root == note).toSet(),
      ));

  Future<void> call({
    required String source,
    required final int index,
  }) async {
    final data = await loader.load(source);

    final pcp = chromaCalculable
        .call(data.cutEvaluationAudioByIndex(index))
        .average()
        .first;

    const scoreCalculator = ScoreCalculator.cosine();

    final noteScores = <Note, double>{};

    for (final note in Note.sharpNotes) {
      final template = _buildTemplate(note);
      final score = scoreCalculator(pcp, template);
      noteScores[note] = score;
    }

    final sortedScores = noteScores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    for (final MapEntry(:key, :value) in sortedScores) {
      logTest('$key: $value');
    }
  }
}
