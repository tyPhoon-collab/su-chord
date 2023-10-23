import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../service.dart';
import '../../utils/loaders/audio.dart';
import '../../utils/measure.dart';
import '../../widgets/plot_view.dart';
import '../cache_manager.dart';
import '../chord.dart';
import '../chord_progression.dart';
import '../chord_selector.dart';
import '../chroma.dart';
import '../chroma_calculators/chroma_calculator.dart';
import '../debug.dart';
import '../filter.dart';

abstract interface class ChordEstimable {
  ChordProgression estimate(AudioData data, [bool flush = true]);

  ChordProgression flush();
}

///Chromaからコードを推定する場合は、このクラスを継承すると良い
abstract class ChromaChordEstimator
    with Measure, SampleRateCacheManager
    implements ChordEstimable, HasDebugViews {
  ChromaChordEstimator({
    required this.chromaCalculable,
    this.filters = const [],
  });

  //service.dartから読み込んでいる。フロントエンドと同じコードタイプをデフォルトで扱える
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

    final progression = measure(
      'estimate',
      () => estimateFromChroma(_filteredChromas),
    );

    if (flush) _flush();
    return progression;
  }

  @override
  ChordProgression flush() => estimate(AudioData.empty());

  void _flush() {
    _chromas = [];
  }

  ChordProgression estimateFromChroma(List<Chroma> chroma);

  @override
  List<DebugChip> build() => [
        DebugChip(
          titleText: 'Chromagram',
          child: Chromagram(chromas: _filteredChromas),
        ),
        // if (chromaCalculable case final HasMagnitudes hasMagnitudes)
        //   if (hasMagnitudes.cachedMagnitudes case final Magnitudes mag)
        //     SpectrogramChart(magnitudes: mag),
        DebugChip(
          titleText: 'Chroma List Size',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('chroma list size: ${_chromas.length}'),
              Text('filtered chroma list size: ${_filteredChromas.length}'),
            ],
          ),
        ),
        DebugChip(
          titleText: 'Calculate Times',
          child: CalculateTimeTableView(table: calculateTimes),
        )
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
    for (final c in _filteredChromas) {
      final chords = estimateOneFromChroma(c);
      final chord = chordSelectable(chords, progression);
      progression.add(chord);
    }

    return progression;
  }

  Iterable<Chord> estimateOneFromChroma(Chroma chroma);
}
