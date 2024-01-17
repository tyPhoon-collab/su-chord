import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

import '../../utils/loaders/audio.dart';
import '../../utils/measure.dart';
import '../../widgets/plot_view.dart';
import '../annotation.dart';
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

abstract interface class ChromaChordEstimatorOverridable {
  List<Slice>? slices(
      covariant ChromaChordEstimator estimator, AudioData audioData);
}

///Chromaからコードを推定する場合は、このクラスを継承すると良い
abstract class ChromaChordEstimator
    with Measure, SampleRateCacheManager
    implements ChordEstimable, HasDebugViews, HasChromaList {
  ChromaChordEstimator({
    required this.chromaCalculable,
    this.chordChangeDetectable = const FrameChordChangeDetector(),
    this.filters = const [],
    this.overridable,
  });

  final ChromaCalculable chromaCalculable;
  final Iterable<ChromaListFilter> filters;
  final ChromaChordChangeDetectable chordChangeDetectable;

  ///実験のしやすさのために、いくつかのプロパティを強制的に上書きする
  ///例えば、コードチェンジを推定ではなく、指定するなど
  final ChromaChordEstimatorOverridable? overridable;

  List<Chroma> _chromas = [];
  List<Chroma> _filteredChromas = [];
  List<Chroma> _slicedChromas = [];
  double _deltaTime = 0;

  @override
  String toString() => chromaCalculable.toString();

  @override
  void onSampleRateChanged(int newSampleRate) {
    _deltaTime = chromaCalculable.deltaTime(newSampleRate);
  }

  @override
  ChordProgression<Chord> estimate(AudioData data, [bool flush = true]) {
    updateCacheSampleRate(data.sampleRate);
    final chroma = measure(
      'chroma calc',
      () => chromaCalculable(data, flush),
      withTotal: true,
    );

    _chromas.addAll(chroma);

    _filteredChromas = measure(
      'filter calc',
      () => filters.fold(_chromas, (pre, filter) => filter(pre)),
      withTotal: true,
    );

    final slices = measure(
      'HCDF calc',
      () =>
          overridable?.slices(this, data) ??
          chordChangeDetectable(_filteredChromas),
      withTotal: true,
    );

    _slicedChromas = _filteredChromas.average(slices);

    final progression = measure(
      'estimate calc',
      () => estimateFromChroma(_slicedChromas),
      withTotal: true,
    );

    if (flush) _flush();
    return ChordProgression(progression
        .mapIndexed(
            (i, chord) => chord.copyWith(time: slices[i].toTime(_deltaTime)))
        .toList());
  }

  @override
  ChordProgression<Chord> flush() => estimate(AudioData.empty());

  void _flush() {
    _chromas = [];
    calculateTimes.clear();
  }

  ChordProgression<Chord> estimateFromChroma(List<Chroma> chroma);

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
          builder: (_) => CalculateTimeTableView(
            table: calculateTimes,
            needsKeySort: true,
          ),
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
    super.overridable,
    this.chordSelectable,
  });

  final ChordSelectable? chordSelectable;

  @override
  String toString() =>
      '${super.toString()}, ${chordSelectable?.toString() ?? 'first'}';

  @override
  ChordProgression<Chord> estimateFromChroma(List<Chroma> chroma) {
    final progression =
        ChordProgression(chroma.map(getUnselectedMultiChordCell).toList());

    return chordSelectable?.call(progression) ?? progression;
  }

  MultiChordCell<Chord> getUnselectedMultiChordCell(Chroma chroma);
}
