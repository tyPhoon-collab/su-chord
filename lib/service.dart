import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'domains/chord.dart';
import 'domains/equal_temperament.dart';
import 'domains/estimator.dart';
import 'domains/factory.dart';
import 'domains/magnitudes_calculator.dart';

part 'service.g.dart';

///サンプルレートやSTFT時のwindowサイズやhop_lengthのサイズを保持する
///推定器に必要なデータを全て保持し、EstimatorFactoryに提供する
///Providerとして扱うことで、変更時にfactoryも更新できる
@riverpod
EstimatorFactoryContext factoryContext(FactoryContextRef ref) =>
    const EstimatorFactoryContext(
      chunkSize: 8192,
      chunkStride: 0,
      sampleRate: 22050,
    );

@riverpod
EstimatorFactory factory(FactoryRef ref) =>
    EstimatorFactory(ref.watch(factoryContextProvider));

@riverpod
class DetectableChords extends _$DetectableChords {
  static final qualities = {
    '',
    'm',
    'aug',
    'dim',
    'sus4',
    '7',
    'm7',
    'M7',
    'mM7',
    'aug7',
    'm7b5',
    '7sus4',
    'dim7',
    // '6',
    // 'm6',
    'add9',
  };

  static Set<Chord> _fromQualities(Set<String> qualities) {
    return Set.unmodifiable([
      for (final root in Note.values)
        for (final quality in qualities) Chord.parse(root.toString() + quality)
    ]);
  }

  @override
  Set<Chord> build() => _fromQualities(qualities);

  void setFromQualities(Set<String> qualities) {
    state = _fromQualities(qualities);
  }
}

///推定器の一覧
///フロントエンドでどの推定器を使うか選ぶことができる
@riverpod
Map<String, AsyncValueGetter<ChordEstimable>> estimators(EstimatorsRef ref) {
  final factory = ref.watch(factoryProvider);
  final detectableChords = ref.watch(detectableChordsProvider);
  final filters = factory.filter.eval; //TODO deal as provider

  return {
    'matching + reassignment': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignment,
          filters: filters,
          templates: detectableChords,
        ),
    'matching + reassignment comb': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignCombFilter,
          filters: filters,
          templates: detectableChords,
        ),
    'matching + comb': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
          templates: detectableChords,
        ),
    'search tree + comb': () async => SearchTreeChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
          noteExtractable: factory.extractor.threshold(),
          chordSelectable: await factory.selector.db,
          detectableChords: detectableChords,
        ),
    'search tree + comb + ln scale': () async => SearchTreeChordEstimator(
          chromaCalculable: factory.guitarRange.combFilterWith(
            magnitudesCalculable:
                factory.magnitude.stft(scalar: MagnitudeScalar.ln),
          ),
          filters: filters,
          noteExtractable: factory.extractor.threshold(
            scalar: MagnitudeScalar.ln,
          ),
          chordSelectable: await factory.selector.db,
          detectableChords: detectableChords,
        ),
    'from notes + reassignment comb': () async => FromNotesChordEstimator(
          chromaCalculable: factory.guitarRange.reassignCombFilter,
          filters: filters,
          noteExtractable: factory.extractor.threshold(),
          detectableChords: detectableChords,
        ),
  };
}

@riverpod
class SelectingEstimatorLabel extends _$SelectingEstimatorLabel {
  @override
  String build() => 'matching + reassignment comb';

  //ignore: use_setters_to_change_properties
  void change(String newValue) => state = newValue;
}

@riverpod
Future<ChordEstimable> estimator(EstimatorRef ref) {
  final estimators = ref.watch(estimatorsProvider);
  final label = ref.watch(selectingEstimatorLabelProvider);
  return estimators[label]!.call();
}

@riverpod
class IsVisibleDebug extends _$IsVisibleDebug {
  @override
  bool build() => true;

  void toggle() => state = !state;
}
