import 'package:get/get.dart';

import '../utils/loaders/csv.dart';
import 'chord_selector.dart';
import 'chroma.dart';
import 'chroma_calculators/chroma_calculator.dart';
import 'chroma_calculators/comb_filter.dart';
import 'chroma_calculators/reassignment.dart';
import 'equal_temperament.dart';
import 'filter.dart';
import 'magnitudes_calculator.dart';
import 'note_extractor.dart';

typedef Filters = List<ChromaListFilter>;

final factory2048_1024 = EstimatorFactory(
  const EstimatorFactoryContext(
    chunkSize: 2048,
    chunkStride: 1024,
    sampleRate: 22050,
  ),
);

final factory8192_0 = EstimatorFactory(
  const EstimatorFactoryContext(
    chunkSize: 8192,
    chunkStride: 0,
    sampleRate: 22050,
  ),
);

final class EstimatorFactoryContext {
  const EstimatorFactoryContext({
    required this.chunkSize,
    required this.chunkStride,
    required this.sampleRate,
  });

  final int chunkSize;
  final int chunkStride;
  final int sampleRate;

  double get dt => (chunkStride == 0 ? chunkSize : chunkStride) / sampleRate;

  @override
  String toString() =>
      'chunkSize: $chunkSize, chunkStride: $chunkStride, sampleRate: $sampleRate';
}

///必要な情報をContextに閉じ込めることによって、DIを簡単にするためのファクトリ
final class EstimatorFactory {
  EstimatorFactory(this.context);

  final EstimatorFactoryContext context;

  late final filter = FilterFactory(context);
  late final magnitude = MagnitudesFactory(context);
  late final selector = ChordSelectorFactory();
  late final extractor = NoteExtractorFactory();

  late final guitarRange = ChromaCalculatorFactory(
    context,
    magnitude: magnitude,
    chromaContext: const ChromaContext(
      lowest: MusicalScale.E2,
      perOctave: 6,
    ),
  );
  late final bigRange = ChromaCalculatorFactory(
    context,
    magnitude: magnitude,
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
  }) =>
      ReassignmentMagnitudesCalculator(
        chunkSize: context.chunkSize,
        chunkStride: context.chunkStride,
        scalar: scalar,
      );
}

final class ChromaCalculatorFactory {
  const ChromaCalculatorFactory(
    this.context, {
    this.chromaContext = const ChromaContext(),
    required this.magnitude,
  });

  final EstimatorFactoryContext context;
  final ChromaContext chromaContext;
  final MagnitudesFactory magnitude;

  int get _chunkStride => context.chunkStride;

  int get _chunkSize => context.chunkSize;

  ChromaCalculable get combFilter => combFilterWith();

  ChromaCalculable get reassignCombFilter =>
      combFilterWith(magnitudesCalculable: magnitude.reassignment());

  ChromaCalculable combFilterWith({
    CombFilterContext? combFilterContext,
    MagnitudesCalculable? magnitudesCalculable,
  }) =>
      CombFilterChromaCalculator(
        magnitudesCalculable: magnitudesCalculable ?? magnitude.stft(),
        chromaContext: chromaContext,
        context: combFilterContext ?? const CombFilterContext(),
      );

  ChromaCalculable get reassignment => reassignmentWith();

  ChromaCalculable reassignmentWith({MagnitudeScalar? scalar}) =>
      ReassignmentChromaCalculator(
        chunkSize: _chunkSize,
        chunkStride: _chunkStride,
        chromaContext: chromaContext,
        scalar: scalar ?? MagnitudeScalar.none,
      );
}

final class FilterFactory {
  const FilterFactory(this.context);

  final EstimatorFactoryContext context;

  Filters get eval => [interval(4.seconds)];

  Filters get realtime => [
        ThresholdFilter(threshold: 10),
        TriadChordChangeDetector(),
      ];

  ChromaListFilter interval(Duration duration) =>
      IntervalChordChangeDetector(interval: duration, dt: context.dt);
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
