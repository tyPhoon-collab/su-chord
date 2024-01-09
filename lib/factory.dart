import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'domains/chord_selector.dart';
import 'domains/chroma.dart';
import 'domains/chroma_calculators/chroma_calculator.dart';
import 'domains/chroma_calculators/comb_filter.dart';
import 'domains/chroma_calculators/reassignment.dart';
import 'domains/filters/chord_change_detector.dart';
import 'domains/magnitudes_calculator.dart';
import 'domains/note_extractor.dart';
import 'domains/score_calculator.dart';
import 'utils/loaders/csv.dart';

EstimatorFactory eFactory({
  required int chunkSize,
  int chunkStride = 0,
  int sampleRate = 22050,
  NamedWindowFunction windowFunction = NamedWindowFunction.hanning,
}) =>
    EstimatorFactory(
      EstimatorFactoryContext(
        chunkSize: chunkSize,
        chunkStride: chunkStride,
        sampleRate: sampleRate,
        windowFunction: windowFunction,
      ),
    );

final f_1024 = eFactory(chunkSize: 1024);
final f_2048 = eFactory(chunkSize: 2048);
final f_4096 = eFactory(chunkSize: 4096);
final f_8192 = eFactory(chunkSize: 8192);
final f_16384 = eFactory(chunkSize: 16384);

final class EstimatorFactoryContext {
  const EstimatorFactoryContext({
    required this.chunkSize,
    required this.chunkStride,
    required this.sampleRate,
    required this.windowFunction,
  });

  final int chunkSize;
  final int chunkStride;
  final int sampleRate;
  final NamedWindowFunction windowFunction;

  int get _chunkStride => chunkStride == 0 ? chunkSize : chunkStride;

  double get deltaTime => _chunkStride / sampleRate;

  double get deltaFrequency => sampleRate / chunkSize;

  @override
  String toString() =>
      'chunkSize $chunkSize, chunkStride $chunkStride, sampleRate $sampleRate, window ${windowFunction.name}';
}

///必要な情報をContextに閉じ込めることによって、DIを簡単にするためのファクトリ
///また、統一したAPIを提供することで、扱いやすくする
///同時に破壊的な変更時に、修正が最小限になるようにする
final class EstimatorFactory {
  EstimatorFactory(this.context);

  final EstimatorFactoryContext context;

  late final hcdf = HCDFFactory(context);
  late final magnitude = MagnitudesFactory(context);
  late final selector = ChordSelectorFactory();
  late final extractor = NoteExtractorFactory();

  late final guitar = ChromaCalculatorFactory(
    context,
    magnitude: magnitude,
    chromaContext: ChromaContext.guitar,
  );
  late final big = ChromaCalculatorFactory(
    context,
    magnitude: magnitude,
    chromaContext: ChromaContext.big,
  );

  EstimatorFactory copyWith({
    int? chunkSize,
    int? chunkStride,
    int? sampleRate,
    NamedWindowFunction? windowFunction,
  }) =>
      EstimatorFactory(EstimatorFactoryContext(
        chunkSize: chunkSize ?? context.chunkSize,
        chunkStride: chunkStride ?? context.chunkStride,
        sampleRate: sampleRate ?? context.sampleRate,
        windowFunction: windowFunction ?? context.windowFunction,
      ));
}

final class MagnitudesFactory {
  MagnitudesFactory(this._context);

  final EstimatorFactoryContext _context;

  @factory
  MagnitudesCalculable stft({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    NamedWindowFunction windowFunction = NamedWindowFunction.hanning,
  }) =>
      MagnitudesCalculator(
        _buildSTFTCalculator(_context, windowFunction),
        scalar: scalar,
      );

  ///[useGreaterChunkSize]がtrueなら
  ///[overrideChunkSize]が[_context.chunkSize]より小さい場合に
  ///[_context.chunkSize]を用いる
  @factory
  MagnitudesCalculable reassignment({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    NamedWindowFunction windowFunction = NamedWindowFunction.hanning,
    int? overrideChunkSize = 8192,
    bool useGreaterChunkSize = true,
  }) {
    if (useGreaterChunkSize &&
        overrideChunkSize != null &&
        overrideChunkSize < _context.chunkSize) {
      overrideChunkSize = null;
    }
    return ReassignmentMagnitudesCalculator(
      ReassignmentCalculator(
        _buildSTFTCalculator(_context, windowFunction),
        scalar: scalar,
      ),
      overrideChunkSize: overrideChunkSize,
    );
  }
}

final class ChromaCalculatorFactory {
  const ChromaCalculatorFactory(
    this._context, {
    required this.chromaContext,
    required MagnitudesFactory magnitude,
  }) : _magnitude = magnitude;

  final EstimatorFactoryContext _context;
  final ChromaContext chromaContext;
  final MagnitudesFactory _magnitude;

  ChromaCalculable reassignCombFilter({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    NamedWindowFunction windowFunction = NamedWindowFunction.hanning,
    CombFilterContext? combFilterContext,
    int overrideChunkSize = 8192,
    bool useGreaterChunkSize = true,
  }) =>
      combFilter(
        combFilterContext: combFilterContext,
        magnitudesCalculable: _magnitude.reassignment(
          scalar: scalar,
          windowFunction: windowFunction,
          overrideChunkSize: overrideChunkSize,
          useGreaterChunkSize: useGreaterChunkSize,
        ),
      );

  ChromaCalculable stftCombFilter({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    NamedWindowFunction windowFunction = NamedWindowFunction.hanning,
    CombFilterContext? combFilterContext,
  }) =>
      combFilter(
        combFilterContext: combFilterContext,
        magnitudesCalculable:
            _magnitude.stft(scalar: scalar, windowFunction: windowFunction),
      );

  @factory
  ChromaCalculable combFilter({
    CombFilterContext? combFilterContext,
    MagnitudesCalculable? magnitudesCalculable,
  }) =>
      CombFilterChromaCalculator(
        magnitudesCalculable: magnitudesCalculable ?? _magnitude.stft(),
        chromaContext: chromaContext,
        context: combFilterContext ?? const CombFilterContext(),
      );

  @factory
  ChromaCalculable reassignment({
    MagnitudeScalar? scalar,
    NamedWindowFunction windowFunction = NamedWindowFunction.hanning,
    isReassignFrequency = true,
    isReassignTime = false,
  }) =>
      ReassignmentETScaleChromaCalculator(
        ReassignmentCalculator(
          _buildSTFTCalculator(_context, windowFunction),
          isReassignFrequency: isReassignFrequency,
          isReassignTime: isReassignTime,
          scalar: scalar ?? MagnitudeScalar.none,
        ),
        chromaContext: chromaContext,
      );
}

final class HCDFFactory {
  const HCDFFactory(this._context);

  final EstimatorFactoryContext _context;

  ///評価音源のための簡易的なクロマフィルタ
  ChromaChordChangeDetectable get eval => interval(4.seconds);

  //TODO Add args
  @factory
  ChromaChordChangeDetectable triad({
    required double threshold,
  }) =>
      PowerThresholdChordChangeDetector(
        threshold,
        onPower: TriadChordChangeDetector(),
      );

  @factory
  ChromaChordChangeDetectable frame(double threshold) =>
      PowerThresholdChordChangeDetector(
        threshold,
        onPower: const FrameChordChangeDetector(),
      );

  @factory
  ChromaChordChangeDetectable threshold(
    double threshold, {
    ChromaChordChangeDetectable? onPower,
  }) =>
      PowerThresholdChordChangeDetector(threshold);

  @factory
  ChromaChordChangeDetectable preFrameCheck({
    required double powerThreshold,
    ScoreCalculator scoreCalculator = const ScoreCalculator.cosine(),
    double scoreThreshold = 0.8,
  }) =>
      PowerThresholdChordChangeDetector(
        powerThreshold,
        onPower: PreFrameCheckChordChangeDetector(
          scoreCalculator: scoreCalculator,
          threshold: scoreThreshold,
        ),
      );

  @factory
  ChromaChordChangeDetectable interval(Duration duration) =>
      IntervalChordChangeDetector(
          interval: duration, deltaTime: _context.deltaTime);
}

final class ChordSelectorFactory {
  CSV? _csv;

  @factory
  Future<ChordSelectable> get db async {
    _csv ??= await CSVLoader.db.load();
    return ChordProgressionDBChordSelector.fromCSV(_csv!);
  }

  @factory
  ChordSelectable get flatFive => const FlatFiveChordSelector();
}

final class NoteExtractorFactory {
  ///スケーリングによって、閾値は変わるべき
  ///クライアント側で考えなくて良いように、factoryで管理する
  @factory
  NoteExtractable threshold({
    MagnitudeScalar scalar = MagnitudeScalar.none,
  }) =>
      ThresholdByMaxRatioExtractor(
        ratio: switch (scalar) {
          MagnitudeScalar.none => 0.3,
          MagnitudeScalar.ln => 0.55,
          MagnitudeScalar.dB => 0.5,
        },
      );
}

STFTCalculator _buildSTFTCalculator(
  EstimatorFactoryContext context,
  NamedWindowFunction windowFunction,
) {
  return STFTCalculator.window(
    windowFunction,
    chunkSize: context.chunkSize,
    chunkStride: context.chunkStride,
  );
}
