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

  double deltaTime(int sampleRate);

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

    return magnitudes;
  }

  @override
  double frequency(int index, int sampleRate) =>
      stft.frequency(index, sampleRate.toDouble());

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      stft.indexOfFrequency(freq, sampleRate.toDouble());
}

class ReassignmentMagnitudesCalculator extends ReassignmentCalculator
    with SampleRateCacheManager
    implements MagnitudesCalculable {
  ReassignmentMagnitudesCalculator({
    super.chunkSize,
    super.chunkStride,
    super.isReassignFrequency,
    super.isReassignTime,
    super.scalar,
    this.overrideChunkSize,
  })  : assert(overrideChunkSize == null || isReassignFrequency),
        assert(!isReassignTime, 'not supported now'),
        super.hanning();

  ///再割り当て法は擬似的に周波数分解能を向上させることができる
  ///例えば、chunkSize=2048であっても、overrideChunkSizeを8192とすれば
  ///擬似的に4倍の周波数分解能をトレードオフなしに得ることができる
  ///nullならchunkSizeとして扱う
  //TODO overrideChunkStrideを用意する
  final int? overrideChunkSize;

  late Bin _binY;

  @override
  MagnitudeScalar get magnitudeScalar => scalar;

  int get _chunkSize => overrideChunkSize ?? super.chunkSize;

  @override
  String toString() =>
      'sparse mags ${scalar.name} scaled${overrideChunkSize != null ? ' override by $overrideChunkSize' : ''}';

  @override
  double deltaFrequency(int sampleRate) => sampleRate / _chunkSize;

  @override
  void onSampleRateChanged(int newSampleRate) {
    final df = deltaFrequency(newSampleRate);
    _binY = List.generate(_chunkSize ~/ 2 + 2, (i) => i * df);
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

    return reassignedMagnitudes;
  }

  @override
  double frequency(int index, int sampleRate) =>
      index * sampleRate / _chunkSize;

  @override
  double indexOfFrequency(double freq, int sampleRate) =>
      freq * _chunkSize / sampleRate;
}
