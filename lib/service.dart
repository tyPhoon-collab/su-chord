import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'config.dart';
import 'domains/chord_selector.dart';
import 'domains/estimate.dart';
import 'domains/factory.dart';

part 'service.g.dart';

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

@riverpod
Map<String, AsyncValueGetter<ChordEstimable>> estimators(EstimatorsRef ref) {
  final factory = ref.watch(factoryProvider);
  final filters = factory.filter.eval; //TODO to provider

  return {
    'main': () async => PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignment,
          filters: filters,
        ),
    'comb + search tree': () async => SearchTreeChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
          thresholdRatio: 0.3,
        ),
    'comb + search tree + db': () async {
      final csvString =
          await rootBundle.loadString('assets/csv/chord_progression.csv');
      final csv = const CsvToListConverter().convert(csvString);
      return SearchTreeChordEstimator(
        chromaCalculable: factory.guitarRange.combFilter,
        filters: filters,
        thresholdRatio: 0.3,
        chordSelectable: ChordProgressionDBChordSelector.fromCSV(csv),
      );
    },
  };
}

@riverpod
class SelectingEstimatorLabel extends _$SelectingEstimatorLabel {
  @override
  String build() => 'main';

  void change(String newValue) {
    final estimators = ref.watch(estimatorsProvider);
    if (estimators.keys.contains(newValue)) {
      state = newValue;
    } else {
      throw ArgumentError();
    }
  }
}

@riverpod
Future<ChordEstimable> estimator(EstimatorRef ref) {
  final estimators = ref.watch(estimatorsProvider);
  final label = ref.watch(selectingEstimatorLabelProvider);
  return estimators[label]!.call();
}
