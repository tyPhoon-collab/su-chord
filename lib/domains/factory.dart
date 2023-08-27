import 'chroma.dart';
import 'equal_temperament.dart';
import 'filter.dart';

final class FactoryContext {
  const FactoryContext({
    required this.chunkSize,
    required this.chunkStride,
    required this.sampleRate,
  });

  final int chunkSize;
  final int chunkStride;
  final int sampleRate;

  double get dt => (chunkStride == 0 ? chunkSize : chunkStride) / sampleRate;
}

final class EstimatorFactory {
  EstimatorFactory(this.context);

  final FactoryContext context;
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

  final FactoryContext context;
  final MusicalScale lowest;
  final int perOctave;

  ChromaCalculable get combFilter => CombFilterChromaCalculator(
        chunkSize: context.chunkSize,
        chunkStride: context.chunkStride,
        lowest: lowest,
        perOctave: perOctave,
      );

  ChromaCalculable get reassignment => ReassignmentChromaCalculator(
        chunkSize: context.chunkSize,
        chunkStride: context.chunkStride,
        lowest: lowest,
        perOctave: perOctave,
      );
}

final class FilterFactory {
  const FilterFactory(this.context);

  final FactoryContext context;

  List<ChromaListFilter> get eval => [
        IntervalChordChangeDetector(interval: 4, dt: context.dt),
      ];
}
