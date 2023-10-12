import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../chroma.dart';
import 'chroma_calculator.dart';

abstract interface class MagnitudesCalculable implements HasMagnitudes {
  Magnitudes call(AudioData data, [bool flush = true]);
}

abstract interface class HasMagnitudes {
  MagnitudeScalar get magnitudeScalar;

  Magnitudes get cachedMagnitudes; // for debug view

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
  String toString() => 'stft mags ${scalar.name} scaled';

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  final Magnitudes _cachedMagnitudes = [];

  @override
  Magnitudes call(AudioData data, [bool flush = true]) {
    final magnitudes = <Float64List>[];
    void callback(Float64x2List freq) =>
        magnitudes.add(scalar(freq.discardConjugates().magnitudes()));
    stft.stream(data.buffer, callback, chunkStride);
    if (flush) stft.flush(callback);

    if (flush) {
      _cachedMagnitudes.clear();
    } else {
      _cachedMagnitudes.addAll(magnitudes);
    }

    return magnitudes;
  }

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());

  @override
  Magnitudes get cachedMagnitudes => _cachedMagnitudes;
}

class ReassignmentMagnitudesCalculator extends ReassignmentCalculator
    implements MagnitudesCalculable {
  ReassignmentMagnitudesCalculator({
    super.chunkSize,
    super.chunkStride,
    super.scalar,
  }) : super.hanning();

  @override
  String toString() => 'sparse mags ${scalar.name} scaled';

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  final Magnitudes _cachedMagnitudes = [];

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

    final reassignedMagnitudes = WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: binY,
    ).values;

    if (flush) {
      _cachedMagnitudes.clear();
    } else {
      _cachedMagnitudes.addAll(reassignedMagnitudes);
    }

    return reassignedMagnitudes;
  }

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());

  @override
  Magnitudes get cachedMagnitudes => _cachedMagnitudes;
}
