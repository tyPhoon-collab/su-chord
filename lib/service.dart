import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'config.dart';
import 'domains/chroma_calculators/magnitudes_calculator.dart';
import 'domains/estimator.dart';
import 'domains/factory.dart';

part 'service.g.dart';

///サンプルレートやSTFT時のwindowサイズやhop_lengthのサイズを保持する
///推定器に必要なデータを全て保持し、EstimatorFactoryに提供する
///Providerとして扱うことで、変更時にfactoryも更新できる
@riverpod
EstimatorFactoryContext factoryContext(FactoryContextRef ref) =>
    const EstimatorFactoryContext(
      chunkSize: 8192,
      chunkStride: 0,
      sampleRate: Config.sampleRate,
    );

@riverpod
EstimatorFactory factory(FactoryRef ref) =>
    EstimatorFactory(ref.watch(factoryContextProvider));

///推定器の一覧
///フロントエンドでどの推定器を使うか選ぶことができる
///
@riverpod
Map<String, AsyncValueGetter<ChordEstimable>> estimators(EstimatorsRef ref) {
  final factory = ref.watch(factoryProvider);
  final filters = factory.filter.eval; //TODO deal as provider or hardcoding.

  return {
    'matching + reassignment': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignment,
          filters: filters,
        ),
    'matching + reassignment comb': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignCombFilter,
          filters: filters,
        ),
    'matching + comb': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
        ),
    'search tree + comb': () async => SearchTreeChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
          thresholdRatio: 0.3,
        ),
    'search tree + comb + ln scale': () async => SearchTreeChordEstimator(
          chromaCalculable: factory.guitarRange.combFilterWith(
            magnitudesCalculable:
                factory.magnitude.stft(scalar: MagnitudeScalar.ln),
          ),
          filters: filters,
          thresholdRatio: 0.3,
        ),
  };
}

@riverpod
class SelectingEstimatorLabel extends _$SelectingEstimatorLabel {
  @override
  String build() => ref.watch(estimatorsProvider).keys.first;

  void change(String newValue) {
    final estimators = ref.watch(estimatorsProvider);
    assert(estimators.keys.contains(newValue));
    state = newValue;
  }
}

@riverpod
Future<ChordEstimable> estimator(EstimatorRef ref) {
  final estimators = ref.watch(estimatorsProvider);
  final label = ref.watch(selectingEstimatorLabelProvider);
  return estimators[label]!.call();
}
