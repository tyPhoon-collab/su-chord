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
import 'filter.dart';
import 'note_extractor.dart';

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
    this.chordSelectable = const FirstChordSelector(),
  });

  final ChordSelectable chordSelectable;

  @override
  String toString() => '${super.toString()}, $chordSelectable';

  @override
  ChordProgression estimateFromChroma(List<Chroma> chroma) {
    final progression = ChordProgression.empty();
    measure('estimate', () {
      for (final c in _filteredChromas) {
        final chords = estimateOneFromChroma(c);
        final chord = chordSelectable(chords, progression);
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
///探索木に関しては、「推定された音を含むコード群を返す」計算なので、
///計算量は増える<O(log(n)) -> O(n)>が同じ動作をする関数として実装している
class SearchTreeChordEstimator extends SelectableChromaChordEstimator {
  SearchTreeChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.noteExtractable = const ThresholdByMaxRatioExtractor(),
    Set<Chord>? detectableChords,
  })  : detectableChords =
            detectableChords ?? ChromaChordEstimator.defaultDetectableChords,
        assert(
          chordSelectable is! FirstChordSelector,
          'Search Tree SHOULD NOT use FirstChordSelector as chordSelectable',
        );

  final Set<Chord> detectableChords;
  final NoteExtractable noteExtractable;

  @override
  String toString() => 'search tree $noteExtractable, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    final notes = noteExtractable(chroma);
    return detectableChords
        .where((e) => notes.every((note) => e.notes.contains(note)));
  }
}

///クロマから演奏音を抽出し、その演奏音全てを含むコードのみを返す
///もし、複数ある場合は、[ChordSelectable]によって絞り込みを行う
class FromNotesChordEstimator extends SelectableChromaChordEstimator {
  FromNotesChordEstimator({
    required super.chromaCalculable,
    super.chordSelectable,
    super.filters,
    this.noteExtractable = const ThresholdByMaxRatioExtractor(),
    Set<Chord>? detectableChords,
  }) : detectableChords =
            detectableChords ?? ChromaChordEstimator.defaultDetectableChords;

  final Set<Chord> detectableChords;
  final NoteExtractable noteExtractable;

  @override
  String toString() => 'from notes $noteExtractable, ${super.toString()}';

  @override
  Iterable<Chord> estimateOneFromChroma(Chroma chroma) {
    final chords = Chord.fromNotes(noteExtractable(chroma)).toSet();
    return chords.intersection(detectableChords);
  }
}
