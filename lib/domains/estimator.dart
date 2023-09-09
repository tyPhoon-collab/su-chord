import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../config.dart';
import '../utils/loader/audio.dart';
import '../utils/measure.dart';
import 'chord.dart';
import 'chord_progression.dart';
import 'chord_selector.dart';
import 'chroma.dart';
import 'equal_temperament.dart';
import 'filter.dart';

abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data, [bool flush = true]);

  ChordProgression flush();
}

abstract interface class Debuggable {
  Iterable<String> debugText();
}

///Chromaからコードを推定する場合は、このクラスを継承すると良い
abstract class ChromaChordEstimator
    with Measure
    implements ChordEstimable, Debuggable {
  ChromaChordEstimator({
    required this.chromaCalculable,
    this.filters = const [],
  });

  final ChromaCalculable chromaCalculable;
  final Iterable<ChromaListFilter> filters;

  List<Chroma> chromas = [];

  //Debugs
  List<Chroma> reducedChromas = [];

  @override
  ChordProgression estimate(AudioData data, [bool flush = true]) {
    final chroma = measure(
      'chroma calc',
      () => chromaCalculable(data, flush),
    );
    chromas.addAll(chroma);

    reducedChromas = measure(
      'filter calc',
      () => filters.fold(chromas, (pre, filter) => filter(pre)),
    );

    final progression = estimateFromChroma(reducedChromas);

    if (flush) _flush();
    return progression;
  }

  @override
  ChordProgression flush() {
    return estimate(AudioData.empty());
  }

  void _flush() {
    chromas = [];
    // reducedChromas = [];
  }

  ChordProgression estimateFromChroma(List<Chroma> chroma);

  @override
  Iterable<String> debugText() {
    return [
      ...reducedChromas.map((e) => e.toString()),
      ...calculateTimes.entries.map((entry) => '${entry.key}: ${entry.value}')
    ];
  }
}

abstract class SelectableChromaChordEstimator extends ChromaChordEstimator {
  SelectableChromaChordEstimator({
    required super.chromaCalculable,
    super.filters,
    ChordSelectable? chordSelectable,
  }) : chordSelectable = chordSelectable ?? FirstChordSelector();

  final ChordSelectable chordSelectable;

  @override
  ChordProgression estimateFromChroma(List<Chroma> chroma) {
    final progression = ChordProgression.empty();
    measure('estimate', () {
      for (final c in reducedChromas) {
        final chord = chordSelectable(estimateOneFromChroma(c), progression);
        progression.add(chord);
      }
    });

    return progression;
  }

  Iterable<Chord> estimateOneFromChroma(Chroma chroma);
}

enum TemplateChromaScalarType {
  ///３倍音を操作する
  ///３倍音は3fの整数倍倍音で、平均律では12+4度が該当する
  thirdHarmonic,
  none;
}

@immutable
class TemplateChromaScalar {
  const TemplateChromaScalar({required this.type, required this.factor});

  factory TemplateChromaScalar.thirdHarmonic(double factor) =>
      TemplateChromaScalar(
        type: TemplateChromaScalarType.thirdHarmonic,
        factor: factor,
      );

  static const none = TemplateChromaScalar(
    type: TemplateChromaScalarType.none,
    factor: 0,
  );

  final TemplateChromaScalarType type;
  final double factor;

  Chroma call(Chroma c) {
    switch (type) {
      case TemplateChromaScalarType.thirdHarmonic:
        return (c * factor).shift(16) + c;
      case TemplateChromaScalarType.none:
        return c;
    }
  }
}

class PatternMatchingChordEstimator extends SelectableChromaChordEstimator {
  PatternMatchingChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.scalar = TemplateChromaScalar.none,
    Set<Chord>? templates,
  })  : assert(templates == null || templates.isNotEmpty),
        templates = templates ?? Config.detectableChords;

  final Set<Chord> templates;
  final TemplateChromaScalar scalar;

  late final templateChromas = groupBy(templates, (p0) => scalar(p0.pcp));

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    return maxBy(templateChromas.entries,
            (entry) => chroma.cosineSimilarity(entry.key))!
        .value;
  }
}

///此木の論文を元に実装
///内部的には探索木を用いてはいないが、
///クロマから音高を導き、音高からコードを導くという点では全く同じ動作をする
class SearchTreeChordEstimator extends SelectableChromaChordEstimator {
  SearchTreeChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.thresholdRatio = 0.65,
    Set<Chord>? detectableChords,
  }) : detectableChords = detectableChords ?? Config.detectableChords;

  final double thresholdRatio;
  final Set<Chord> detectableChords;

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    final chords = Chord.fromNotes(_chooseNotes(chroma)).toSet();
    return chords.intersection(detectableChords);
  }

  Notes _chooseNotes(Chroma chroma) {
    final indexes = chroma.maxSortedIndexes;
    final max = chroma[indexes.first];
    final threshold = max * thresholdRatio;
    final notes = indexes
        .toList()
        .sublist(0, 4)
        .where((e) => chroma[e] >= threshold)
        .map((e) => Note.fromIndex(e));

    return notes;
  }
}
