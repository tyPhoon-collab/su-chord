import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/fftea.dart';

import '../utils/histogram.dart';
import '../utils/loaders/audio.dart';
import 'cache_manager.dart';
import 'chroma.dart';
import 'chroma_calculators/chroma_calculator.dart';

abstract interface class MagnitudesCalculable implements HasMagnitudes {
  Magnitudes call(AudioData data, [bool flush = true]);
}

abstract interface class HasMagnitudes {
  MagnitudeScalar get magnitudeScalar;

  Magnitudes get cachedMagnitudes; // for debug view

  double indexOfFrequency(double freq, int sampleRate);

  double time(int index, int sampleRate);

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
          final value = 20 * _log10(list[i] / referenceMagnitude);
          list[i] = max(value, -80);
        }
        return list;
      case none:
        return list;
    }
  }

  double _log10(double x) => log(x) / ln10;
}

class MagnitudesCalculator extends STFTCalculator
    with MagnitudesCacheManager
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

  @override
  Magnitudes call(AudioData data, [bool flush = true]) {
    final magnitudes = <Float64List>[];
    void callback(Float64x2List freq) =>
        magnitudes.add(scalar(freq.discardConjugates().magnitudes()));
    stft.stream(data.buffer, callback, chunkStride);
    if (flush) stft.flush(callback);

    updateCacheMagnitudes(magnitudes, flush);

    return magnitudes;
  }

  @override
  double time(int index, int sampleRate) => deltaTime(sampleRate) * index;

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());
}

class ReassignmentMagnitudesCalculator extends ReassignmentCalculator
    with MagnitudesCacheManager, SampleRateCacheManager
    implements MagnitudesCalculable {
  ReassignmentMagnitudesCalculator({
    super.chunkSize,
    super.chunkStride,
    super.scalar,
  }) : super.hanning();

  late Bin _binY;

  @override
  String toString() => 'sparse mags ${scalar.name} scaled';

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  @override
  void onSampleRateChanged(int newSampleRate) {
    final df = deltaFrequency(newSampleRate);
    _binY = List.generate(chunkSize ~/ 2 + 2, (i) => i * df);
  }

  @override
  Magnitudes call(AudioData data, [bool flush = true]) {
    final (points, magnitudes) = reassign(data, flush);

    updateCacheSampleRate(data.sampleRate);

    final dt = deltaTime(data.sampleRate);
    final binX = List.generate(magnitudes.length + 1, (i) => i * dt);

    final reassignedMagnitudes = WeightedHistogram2d.from(
      points,
      binX: binX,
      binY: _binY,
    ).values;

    updateCacheMagnitudes(reassignedMagnitudes, flush);

    return reassignedMagnitudes;
  }

  @override
  double time(int index, int sampleRate) => deltaTime(sampleRate) * index;

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());
}
