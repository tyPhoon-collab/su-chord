import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../chroma.dart';
import 'chroma_calculator.dart';

abstract interface class MagnitudesCalculable {
  Magnitudes call(AudioData data, [bool flush = true]);

  double indexOfFrequency(double freq, int sampleRate);

  double frequency(int index, int sampleRate);
}

enum MagnitudeScalar {
  ln,
  dB,
  none;

  Float64List call(Float64List list) {
    switch (this) {
      case ln:
        for (int i = 0; i < list.length; ++i) {
          list[i] = log(list[i] + 1);
        }
        return list;
      case dB:
        const referenceMagnitude = 1;
        for (int i = 0; i < list.length; ++i) {
          list[i] = 20 * _log10(list[i] / referenceMagnitude);
        }
        return list;
      case none:
        return list;
    }
  }

  double _log10(double x) => log(x) / ln10;
}

class MagnitudesCalculator extends STFTCalculator
    implements MagnitudesCalculable {
  MagnitudesCalculator({
    super.chunkSize,
    super.chunkStride,
    this.scalar = MagnitudeScalar.none,
  }) : super.hanning();

  final MagnitudeScalar scalar;

  @override
  Magnitudes call(AudioData data, [bool flush = true]) {
    final magnitudes = <Float64List>[];
    void callback(Float64x2List freq) =>
        magnitudes.add(scalar(freq.discardConjugates().magnitudes()));
    stft.stream(data.buffer, callback, chunkStride);
    if (flush) stft.flush(callback);

    return magnitudes;
  }

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());
}

class ReassignmentMagnitudesCalculator extends ReassignmentCalculator
    implements MagnitudesCalculable {
  ReassignmentMagnitudesCalculator({
    super.chunkSize,
    super.chunkStride,
    super.scalar,
  }) : super.hanning();

  @override
  Magnitudes call(AudioData data, [bool flush = true]) {
    final (points, magnitudes) = reassign(data, flush);

    //TODO improve
    //毎回の計算時にListを再生成するので、メモリ効率が悪い
    //キャッシュ機構などをとることで精度を改善するべき
    final dt = deltaTime(data.sampleRate);
    final df = deltaFrequency(data.sampleRate);
    final binX = List.generate(magnitudes.length + 1, (i) => i * dt);
    final binY = List.generate(chunkSize ~/ 2 + 2, (i) => i * df);

    return WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: binY,
    ).values;
  }

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());
}
