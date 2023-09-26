import 'package:get/get.dart';

import '../config.dart';
import '../utils/loader/csv.dart';
import 'chord_selector.dart';
import 'chroma.dart';
import 'equal_temperament.dart';
import 'filter.dart';

typedef Filters = List<ChromaListFilter>;

final factory2048_1024 = EstimatorFactory(
  const EstimatorFactoryContext(
    chunkSize: 2048,
    chunkStride: 1024,
    sampleRate: Config.sampleRate,
  ),
);

final factory8192_0 = EstimatorFactory(
  const EstimatorFactoryContext(
    chunkSize: 8192,
    chunkStride: 0,
    sampleRate: Config.sampleRate,
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
  late final guitarRange = ChromaCalculatorFactory(
    context,
    chromaContext: const ChromaContext(lowest: MusicalScale.E2, perOctave: 6),
  );
  late final bigRange = ChromaCalculatorFactory(context);

  late final selector = ChordSelectorFactory();
}

final class ChromaCalculatorFactory {
  const ChromaCalculatorFactory(
    this.context, {
    this.chromaContext = const ChromaContext(),
  });

  final EstimatorFactoryContext context;
  final ChromaContext chromaContext;

  int get _chunkStride => context.chunkStride;

  int get _chunkSize => context.chunkSize;

  ChromaCalculable get combFilter => combFilterWith();

  ChromaCalculable combFilterWith(
          {CombFilterContext? context, MagnitudeScalar? scalar}) =>
      CombFilterChromaCalculator(
        chunkSize: _chunkSize,
        chunkStride: _chunkStride,
        chromaContext: chromaContext,
        context: context ?? const CombFilterContext(),
        scalar: scalar ?? MagnitudeScalar.none,
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

  ChordSelectable get first => FirstChordSelector();

  Future<ChordSelectable> get db async {
    _csv ??= await CSVLoader.db.load();
    return ChordProgressionDBChordSelector.fromCSV(_csv!);
  }
}
