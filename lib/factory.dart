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

final factory2048_1024 = EstimatorFactory(const EstimatorFactoryContext(
  chunkSize: 2048,
  chunkStride: 1024,
  sampleRate: 22050,
));

final factory2048_0 = EstimatorFactory(const EstimatorFactoryContext(
  chunkSize: 2048,
  chunkStride: 0,
  sampleRate: 22050,
));

final factory4096_0 = EstimatorFactory(const EstimatorFactoryContext(
  chunkSize: 4096,
  chunkStride: 0,
  sampleRate: 22050,
));

final factory8192_0 = EstimatorFactory(const EstimatorFactoryContext(
  chunkSize: 8192,
  chunkStride: 0,
  sampleRate: 22050,
));

final class EstimatorFactoryContext {
  const EstimatorFactoryContext({
    required this.chunkSize,
    required this.chunkStride,
    required this.sampleRate,
  });

  final int chunkSize;
  final int chunkStride;
  final int sampleRate;

  int get _chunkStride => chunkStride == 0 ? chunkSize : chunkStride;

  double get deltaTime => _chunkStride / sampleRate;

  double get deltaFrequency => sampleRate / chunkSize;

  @override
  String toString() =>
      'chunkSize $chunkSize, chunkStride $chunkStride, sampleRate $sampleRate';
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
}

final class MagnitudesFactory {
  MagnitudesFactory(this.context);

  final EstimatorFactoryContext context;

  MagnitudesCalculable stft({
    MagnitudeScalar scalar = MagnitudeScalar.none,
  }) =>
      MagnitudesCalculator(
        chunkSize: context.chunkSize,
        chunkStride: context.chunkStride,
        scalar: scalar,
      );

  MagnitudesCalculable reassignment({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    int? overrideChunkSize = 8192,
  }) =>
      ReassignmentMagnitudesCalculator(
        chunkSize: context.chunkSize,
        chunkStride: context.chunkStride,
        scalar: scalar,
        overrideChunkSize: overrideChunkSize,
      );
}

final class ChromaCalculatorFactory {
  const ChromaCalculatorFactory(
    this.context, {
    required this.chromaContext,
    required this.magnitude,
  });

  final EstimatorFactoryContext context;
  final ChromaContext chromaContext;
  final MagnitudesFactory magnitude;

  int get _chunkStride => context.chunkStride;

  int get _chunkSize => context.chunkSize;

  ChromaCalculable reassignCombFilter({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    int overrideChunkSize = 8192,
    CombFilterContext? combFilterContext,
  }) =>
      combFilter(
        combFilterContext: combFilterContext,
        magnitudesCalculable: magnitude.reassignment(
          scalar: scalar,
          overrideChunkSize: overrideChunkSize,
        ),
      );

  ChromaCalculable stftCombFilter({
    MagnitudeScalar scalar = MagnitudeScalar.none,
    CombFilterContext? combFilterContext,
  }) =>
      combFilter(
        combFilterContext: combFilterContext,
        magnitudesCalculable: magnitude.stft(scalar: scalar),
      );

  ChromaCalculable combFilter({
    CombFilterContext? combFilterContext,
    MagnitudesCalculable? magnitudesCalculable,
  }) =>
      CombFilterChromaCalculator(
        magnitudesCalculable: magnitudesCalculable ?? magnitude.stft(),
        chromaContext: chromaContext,
        context: combFilterContext ?? const CombFilterContext(),
      );

  ChromaCalculable reassignment({
    MagnitudeScalar? scalar,
    isReassignFrequency = true,
    isReassignTime = false,
  }) =>
      ReassignmentChromaCalculator(
        chunkSize: _chunkSize,
        chunkStride: _chunkStride,
        chromaContext: chromaContext,
        isReassignFrequency: isReassignFrequency,
        isReassignTime: isReassignTime,
        scalar: scalar ?? MagnitudeScalar.none,
      );
}

final class HCDFFactory {
  const HCDFFactory(this.context);

  final EstimatorFactoryContext context;

  ///評価音源のための簡易的なクロマフィルタ
  ChromaChordChangeDetectable get eval => interval(4.seconds);

  //TODO Add args
  ChromaChordChangeDetectable triad({
    required double threshold,
  }) =>
      PowerThresholdChordChangeDetector(
        threshold,
        onPower: TriadChordChangeDetector(),
      );

  ChromaChordChangeDetectable frame(double threshold) =>
      PowerThresholdChordChangeDetector(
        threshold,
        onPower: const FrameChordChangeDetector(),
      );

  ChromaChordChangeDetectable threshold(
    double threshold, {
    ChromaChordChangeDetectable? onPower,
  }) =>
      PowerThresholdChordChangeDetector(threshold);

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

  ChromaChordChangeDetectable interval(Duration duration) =>
      IntervalChordChangeDetector(interval: duration, dt: context.deltaTime);
}

final class ChordSelectorFactory {
  CSV? _csv;

  ChordSelectable get first => const FirstChordSelector();

  Future<ChordSelectable> get db async {
    _csv ??= await CSVLoader.db.load();
    return ChordProgressionDBChordSelector.fromCSV(_csv!);
  }
}

final class NoteExtractorFactory {
  ///スケーリングによって、閾値は変わるべき
  ///クライアント側で考えなくて良いように、factoryで管理する
  NoteExtractable threshold({
    MagnitudeScalar scalar = MagnitudeScalar.none,
  }) =>
      ThresholdByMaxRatioExtractor(
        ratio: switch (scalar) {
          MagnitudeScalar.none => 0.3,
          MagnitudeScalar.ln => 0.5,
          MagnitudeScalar.dB => 0.5,
        },
      );
}
