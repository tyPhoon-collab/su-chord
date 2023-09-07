import 'package:get/get.dart';

import '../config.dart';
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
    lowest: MusicalScale.E2,
    perOctave: 6,
  );
  late final bigRange = ChromaCalculatorFactory(
    context,
    lowest: MusicalScale.C1,
    perOctave: 7,
  );
}

final class ChromaCalculatorFactory {
  const ChromaCalculatorFactory(this.context,
      {required this.lowest, required this.perOctave});

  final EstimatorFactoryContext context;
  final MusicalScale lowest;
  final int perOctave;

  int get _chunkStride => context.chunkStride;

  int get _chunkSize => context.chunkSize;

  ChromaCalculable get combFilter => combFilterWith();

  ChromaCalculable combFilterWith(
          {CombFilterContext? context, MagnitudeScalar? scalar}) =>
      CombFilterChromaCalculator(
        chunkSize: _chunkSize,
        chunkStride: _chunkStride,
        lowest: lowest,
        perOctave: perOctave,
        context: context ?? const CombFilterContext(),
        scalar: scalar ?? MagnitudeScalar.none,
      );

  ChromaCalculable get reassignment => reassignmentWith();

  ChromaCalculable reassignmentWith({MagnitudeScalar? scalar}) =>
      ReassignmentChromaCalculator(
        chunkSize: _chunkSize,
        chunkStride: _chunkStride,
        lowest: lowest,
        perOctave: perOctave,
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
