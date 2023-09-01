import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'config.dart';
import 'domains/chord_selector.dart';
import 'domains/estimate.dart';
import 'domains/factory.dart';
import 'utils/loader.dart';

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
    'main': () async =>
        PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.reassignment,
          filters: filters,
        ),
    'comb + pattern matching': () async =>
        PatternMatchingChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
        ),
    'comb + search tree': () async =>
        SearchTreeChordEstimator(
          chromaCalculable: factory.guitarRange.combFilter,
          filters: filters,
          thresholdRatio: 0.3,
        ),
    'comb + search tree + db': () async {
      late final CSV csv;
      if (kIsWeb || Platform.isIOS || Platform.isAndroid) {
        final csvString =
        await rootBundle.loadString('assets/csv/chord_progression.csv');
        csv = const CsvToListConverter().convert(csvString);
      } else {
        csv = await CSVLoader.db.load();
      }

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
