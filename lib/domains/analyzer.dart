import '../utils/loaders/audio.dart';
import 'magnitudes_calculator.dart';

class LTASCalculator {
  LTASCalculator({required this.magnitudesCalculable});

  final MagnitudesCalculable magnitudesCalculable;

  List<double> call(AudioData data) {
    final mags = magnitudesCalculable(data);

    final frequencyIndexesCount = mags.first.length;

    final ltas = [
      for (int i = 0; i < frequencyIndexesCount; i++)
        mags.fold(0.0, (value, mag) => value + mag[i]) / frequencyIndexesCount
    ];

    assert(ltas.length == frequencyIndexesCount);

    return ltas;
  }
}
