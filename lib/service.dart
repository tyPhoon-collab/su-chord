import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'domains/chord.dart';
import 'domains/chroma_calculators/chroma_calculator.dart';
import 'domains/chroma_mapper.dart';
import 'domains/equal_temperament.dart';
import 'domains/estimator/estimator.dart';
import 'domains/estimator/pattern_matching.dart';
import 'domains/estimator/search.dart';
import 'domains/filters/filter.dart';
import 'domains/magnitudes_calculator.dart';
import 'domains/score_calculator.dart';
import 'factory.dart';

part 'service.g.dart';

///サンプルレートやSTFT時のwindowサイズやhop_lengthのサイズを保持する
///推定器に必要なデータを全て保持し、EstimatorFactoryに提供する
///Providerとして扱うことで、変更時にfactoryも更新できる
@riverpod
EstimatorFactoryContext factoryContext(FactoryContextRef ref) =>
    const EstimatorFactoryContext(
      chunkSize: 4096,
      chunkStride: 0,
      sampleRate: 22050,
      windowFunction: NamedWindowFunction.hanning,
    );

@riverpod
EstimatorFactory factory(FactoryRef ref) =>
    EstimatorFactory(ref.watch(factoryContextProvider));

@riverpod
class DetectableChords extends _$DetectableChords {
  static const qualities = {
    '',
    'm',
    'aug',
    'dim',
    'sus2',
    'sus4',
    '7',
    'm7',
    'M7',
    'mM7',
    'aug7',
    'm7b5',
    '7sus4',
    'dim7',
    '6',
    'm6',
    'add9',
    'madd9',
  };

  ///service.dartから読み込んでいる。フロントエンドと同じコードタイプ群
  static final frontend = fromQualities(qualities);

  ///従来法と同じコードタイプ群
  static final conv = DetectableChords.fromQualities(const {
    '',
    'm',
    'aug',
    'aug7',
    'dim',
    'dim7',
    '7',
    'mM7',
    'M7',
    'm7',
    'm7b5',
    'sus4',
    '7sus4',
    '6',
    'm6',
    'add9',
  });

  static Set<Chord> fromQualities(Set<String> qualities) {
    return Set.unmodifiable([
      for (final root in Note.sharpNotes)
        for (final quality in qualities) Chord.parse('$root$quality')
    ]);
  }

  @override
  Set<Chord> build() => fromQualities(qualities);

  void setFromQualities(Set<String> qualities) {
    state = fromQualities(qualities);
  }
}

///推定器の一覧
///フロントエンドでどの推定器を使うか選ぶことができる
@riverpod
Map<String, AsyncValueGetter<ChordEstimable>> estimators(EstimatorsRef ref) {
  final f = ref.watch(factoryProvider);
  final detectableChords = ref.watch(detectableChordsProvider);

  return {
    'main': () async => PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignment(scalar: MagnitudeScalar.ln),
          chordChangeDetectable: f.hcdf.preFrameCheck(
            powerThreshold: 30,
            scoreThreshold: 0.9,
            scoreCalculator:
                const ScoreCalculator.cosine(ToTonalIntervalVector.musical()),
          ),
          context: TemplateContext.harmonicScaling(
            until: 6,
            templates: detectableChords,
          ),
        ),
    'matching + reassign + template scaled': () async =>
        PatternMatchingChordEstimator(
          chromaCalculable: f.guitar.reassignment(),
          chordChangeDetectable: f.hcdf.preFrameCheck(powerThreshold: 40),
          filters: [
            GaussianFilter.dt(stdDev: 0.5, dt: f.context.deltaTime),
          ],
          context: TemplateContext.harmonicScaling(
            until: 6,
            templates: detectableChords,
          ),
        ),
    'konoki': () async => SearchTreeChordEstimator(
          chromaCalculable: f.guitar.stftCombFilter(scalar: MagnitudeScalar.ln),
          chordChangeDetectable: f.hcdf.preFrameCheck(powerThreshold: 3),
          noteExtractable: f.extractor.threshold(scalar: MagnitudeScalar.ln),
          chordSelectable: await f.selector.db,
          detectableChords: detectableChords,
        ),
  };
}

@riverpod
class SelectingEstimatorLabel extends _$SelectingEstimatorLabel {
  @override
  String build() => 'main';

  //ignore: use_setters_to_change_properties
  void change(String newValue) => state = newValue;
}

@riverpod
Future<ChordEstimable> estimator(EstimatorRef ref) {
  final estimators = ref.watch(estimatorsProvider);
  final label = ref.watch(selectingEstimatorLabelProvider);
  return estimators[label]!.call();
}

@Riverpod(keepAlive: true)
class IsVisibleDebug extends _$IsVisibleDebug {
  @override
  bool build() => false;

  void toggle() => state = !state;
}

@Riverpod(keepAlive: true)
class IsSimplifyChordProgression extends _$IsSimplifyChordProgression {
  @override
  bool build() => true;

  void toggle() => state = !state;
}
