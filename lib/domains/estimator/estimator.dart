import 'package:collection/collection.dart';
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
import '../filters/chord_change_detector.dart';
import '../filters/filter.dart';

abstract interface class ChordEstimable {
  ChordProgression<Chord> estimate(AudioData data, [bool flush = true]);

  ChordProgression<Chord> flush();
}

abstract interface class HasChromaList {
  List<Chroma> chromas();
}

///Chromaからコードを推定する場合は、このクラスを継承すると良い
abstract class ChromaChordEstimator
    with Measure, SampleRateCacheManager
    implements ChordEstimable, HasDebugViews, HasChromaList {
  ChromaChordEstimator({
    required this.chromaCalculable,
    this.chordChangeDetectable = const FrameChordChangeDetector(),
    this.filters = const [],
  });

  //service.dartから読み込んでいる。フロントエンドと同じコードタイプをデフォルトで扱える
  static final defaultDetectableChords =
      ProviderContainer().read(detectableChordsProvider);

  final ChromaCalculable chromaCalculable;
  final Iterable<ChromaListFilter> filters;
  final ChromaChordChangeDetectable chordChangeDetectable;

  List<Chroma> _chromas = [];
  List<Chroma> _filteredChromas = [];
  List<Chroma> _slicedChromas = [];
  double _dt = 0;

  @override
  String toString() => chromaCalculable.toString();

  @override
  void onSampleRateChanged(int newSampleRate) {
    _dt = chromaCalculable.deltaTime(newSampleRate);
  }

  @override
  ChordProgression<Chord> estimate(AudioData data, [bool flush = true]) {
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

    final slices = measure(
      'HCDF calc',
      () => chordChangeDetectable(_filteredChromas),
    );

    _slicedChromas = average(_filteredChromas, slices);

    final progression = measure(
      'estimate calc',
      () => estimateFromChroma(_slicedChromas),
    );

    if (flush) _flush();
    return ChordProgression(progression
        .mapIndexed((i, chord) => ChordCell(
              chord: chord,
              time: slices[i].toTime(_dt),
            ))
        .toList());
  }

  @override
  ChordProgression<Chord> flush() => estimate(AudioData.empty());

  void _flush() {
    _chromas = [];
  }

  Iterable<Chord?> estimateFromChroma(List<Chroma> chroma);

  @override
  List<DebugChip> build() => [
        DebugChip(
          titleText: 'Chromagram',
          builder: (_) => Chromagram(chromas: _slicedChromas),
        ),
        // if (chromaCalculable case final HasMagnitudes hasMagnitudes)
        //   if (hasMagnitudes.cachedMagnitudes case final Magnitudes mag)
        //     SpectrogramChart(magnitudes: mag),
        DebugChip(
          titleText: 'Chroma List Size',
          builder: (_) => Column(
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
          builder: (_) => CalculateTimeTableView(table: calculateTimes),
        )
      ];

  @override
  List<Chroma> chromas() => _chromas.toList();
}

abstract class SelectableChromaChordEstimator extends ChromaChordEstimator {
  SelectableChromaChordEstimator({
    required super.chromaCalculable,
    super.chordChangeDetectable,
    super.filters,
    this.chordSelectable = const FirstChordSelector(),
  });

  final ChordSelectable chordSelectable;

  @override
  String toString() => '${super.toString()}, $chordSelectable';

  @override
  Iterable<Chord?> estimateFromChroma(List<Chroma> chroma) {
    final progression = <Chord?>[];
    for (final c in chroma) {
      final chords = estimateOneFromChroma(c);
      final chord = chordSelectable(chords, progression.nonNulls);
      progression.add(chord);
    }

    return progression;
  }

  Iterable<Chord> estimateOneFromChroma(Chroma chroma);
}
