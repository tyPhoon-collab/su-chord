import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../service.dart';
import '../utils/loaders/audio.dart';
import '../utils/measure.dart';
import '../widgets/plot_view.dart';
import 'cache_manager.dart';
import 'chord.dart';
import 'chord_progression.dart';
import 'chord_selector.dart';
import 'chroma.dart';
import 'chroma_calculators/chroma_calculator.dart';
import 'equal_temperament.dart';
import 'filter.dart';

abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data, [bool flush = true]);

  ChordProgression flush();
}

abstract interface class HasDebugViews {
  List<Widget> build();
}

///Chromaからコードを推定する場合は、このクラスを継承すると良い
abstract class ChromaChordEstimator
    with Measure, SampleRateCacheManager
    implements ChordEstimable, HasDebugViews {
  ChromaChordEstimator({
    required this.chromaCalculable,
    this.filters = const [],
  });

  static final defaultDetectableChords =
      ProviderContainer().read(detectableChordsProvider);

  final ChromaCalculable chromaCalculable;
  final Iterable<ChromaListFilter> filters;

  List<Chroma> _chromas = [];
  List<Chroma> _filteredChromas = [];

  @override
  String toString() => chromaCalculable.toString();

  @override
  ChordProgression estimate(AudioData data, [bool flush = true]) {
    updateCacheSampleRate(data.sampleRate);
    final chroma = measure(
      'chroma calc',
      () => chromaCalculable(data, flush),
    );
    _chromas.addAll(chroma);

    _filteredChromas = measure(
      'filter calc',
      () => filters.fold(_chromas, (pre, filter) => filter(pre)),
    );

    final progression = estimateFromChroma(_filteredChromas);

    if (flush) _flush();
    return progression;
  }

  @override
  ChordProgression flush() {
    return estimate(AudioData.empty());
  }

  void _flush() {
    _chromas = [];
  }

  ChordProgression estimateFromChroma(List<Chroma> chroma);

  @override
  List<Widget> build() => [
        Chromagram(chromas: _filteredChromas),
        // if (chromaCalculable case final HasMagnitudes hasMagnitudes)
        //   if (hasMagnitudes.cachedMagnitudes case final Magnitudes mag)
        //     SpectrogramChart(magnitudes: mag),
        CalculateTimeTableView(table: calculateTimes),
      ];
}

abstract class SelectableChromaChordEstimator extends ChromaChordEstimator {
  SelectableChromaChordEstimator({
    required super.chromaCalculable,
    super.filters,
    ChordSelectable? chordSelectable,
  }) : chordSelectable = chordSelectable ?? FirstChordSelector();

  final ChordSelectable chordSelectable;

  @override
  String toString() => '${super.toString()}, $chordSelectable';

  @override
  ChordProgression estimateFromChroma(List<Chroma> chroma) {
    final progression = ChordProgression.empty();
    measure('estimate', () {
      for (final c in _filteredChromas) {
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

  @override
  String toString() => '${type.name}-$factor';

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
        templates = templates ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> templates;
  final TemplateChromaScalar scalar;

  late final templateChromas = groupBy(templates, (p0) => scalar(p0.pcp));

  @override
  String toString() => 'matching $scalar template scaled, ${super.toString()}';

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
    this.maxNotesCount = 4,
    Set<Chord>? detectableChords,
  }) : detectableChords =
            detectableChords ?? ChromaChordEstimator.defaultDetectableChords;

  final double thresholdRatio;
  final Set<Chord> detectableChords;
  final int maxNotesCount;

  @override
  String toString() =>
      'search tree $thresholdRatio threshold $maxNotesCount notes, ${super.toString()}';

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
        .sublist(0, maxNotesCount)
        .where((e) => chroma[e] >= threshold)
        .map((e) => Note.fromIndex(e));

    return notes;
  }
}
