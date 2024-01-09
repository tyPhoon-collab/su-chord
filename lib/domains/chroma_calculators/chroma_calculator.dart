import 'dart:math' hide Point;
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';

import '../../utils/formula.dart';
import '../../utils/histogram.dart';
import '../../utils/loaders/audio.dart';
import '../chroma.dart';
import '../magnitudes_calculator.dart';

abstract interface class ChromaCalculable {
  List<Chroma> call(AudioData data, [bool flush = true]);

  double deltaTime(int sampleRate);
}

enum NamedWindowFunction {
  hanning,
  hamming,
  blackman,
  blackmanHarris,
  bartlett;

  Float64List toWindow(int chunkSize) => switch (this) {
        NamedWindowFunction.hanning => Window.hanning(chunkSize),
        NamedWindowFunction.hamming => Window.hamming(chunkSize),
        NamedWindowFunction.blackman => Window.blackman(chunkSize),
        NamedWindowFunction.blackmanHarris => _Window.blackmanHarris(chunkSize),
        NamedWindowFunction.bartlett => Window.bartlett(chunkSize),
      };
}

///STFTに必要な変数群を定義したクラス
///窓関数と窓幅、移動幅の責任を持つ
///STFTの計算をする際は、パッケージの実装の都合上、[stft]から行うので
///STFTの計算をする関数自体はこのクラスにはない
class STFTCalculator {
  STFTCalculator({
    required this.window,
    this.chunkSize = 2048,
    this.chunkStride = 1024,
  });

  STFTCalculator.window(
    NamedWindowFunction type, {
    this.chunkSize = 2048,
    this.chunkStride = 1024,
  }) : window = type.toWindow(chunkSize);

  final Float64List window;
  late final STFT stft = STFT(chunkSize, window);
  final int chunkSize;
  final int chunkStride;

  double deltaTime(int sampleRate) =>
      (chunkStride == 0 ? chunkSize : chunkStride) / sampleRate;

  double deltaFrequency(int sampleRate) => sampleRate / chunkSize;
}

class ReassignmentCalculator extends EmbeddedSTFTCalculator {
  ReassignmentCalculator(
    super.stftCalculator, {
    this.isReassignTime = false,
    this.isReassignFrequency = true,
    this.scalar = MagnitudeScalar.none,
    this.aMin = 1e-5,
  }) {
    if (isReassignFrequency) stftD = STFT(chunkSize, windowD);
    if (isReassignTime) stftT = STFT(chunkSize, windowT);
  }

  final MagnitudeScalar scalar;
  final bool isReassignTime;
  final bool isReassignFrequency;
  final double aMin;

  late final windowT = Float64List.fromList(
    window.mapIndexed((i, data) => data * (i - chunkSize / 2)).toList(),
  );
  late final windowD = Float64List.fromList(
    window
        .mapIndexed((i, data) => data - (i > 0 ? window[i - 1] : 0.0))
        .toList(),
  );

  late final STFT stftD;
  late final STFT stftT;

  List<Float64x2List> _calculateSpec(
    STFT stft,
    AudioData data,
    bool flush, [
    void Function(Float64x2List f)? callback,
  ]) {
    late final s = <Float64x2List>[];
    void internalCallback(Float64x2List freq) {
      final f = freq.discardConjugates();
      s.add(f.sublist(0));
      callback?.call(f);
    }

    stft.stream(data.buffer, internalCallback, chunkStride);
    if (flush) stft.flush(internalCallback);

    return s;
  }

  ///デバッグのしやすさとモジュール強度を考慮して
  ///ヒストグラム化する関数と再割り当てする関数を分ける
  (List<Point> points, Magnitudes magnitudes) reassign(
    AudioData data, [
    bool flush = true,
  ]) {
    final Magnitudes magnitudes = [];

    final s = _calculateSpec(
      stft,
      data,
      flush,
      (f) => magnitudes.add(scalar(f.magnitudes())),
    );
    final sD = isReassignFrequency ? _calculateSpec(stftD, data, flush) : [];
    final sT = isReassignTime ? _calculateSpec(stftT, data, flush) : [];

    final points = <Point>[];
    final sr = data.sampleRate;
    final dt = (chunkStride == 0 ? chunkSize : chunkStride) / sr;
    final df = sr / chunkSize;

    for (int i = 0; i < s.length; ++i) {
      for (int j = 0; j < s[i].length; ++j) {
        if (magnitudes[i][j] < aMin) continue;

        final isZero = s[i][j] == Float64x2.zero();

        points.add(Point(
          x: isReassignTime && !isZero
              ? i * dt + complexDivision(sT[i][j], s[i][j]).x / sr
              : i * dt,
          y: isReassignFrequency && !isZero
              ? j * df - complexDivision(sD[i][j], s[i][j]).y * (0.5 * sr / pi)
              : j * df,
          weight: magnitudes[i][j],
        ));
      }
    }

    return (points, magnitudes);
  }
}

extension _Window on Float64List {
  //https://jp.mathworks.com/help/signal/ref/blackmanharris.html
  static Float64List blackmanHarris(int size) {
    final window = Float64List(size);

    const a0 = 0.35875;
    const a1 = 0.48829;
    const a2 = 0.14128;
    const a3 = 0.01168;

    for (var n = 0; n < size; n++) {
      window[n] = a0 +
          -a1 * cos((2 * pi * n) / (size - 1)) +
          a2 * cos((4 * pi * n) / (size - 1)) +
          -a3 * cos((6 * pi * n) / (size - 1));
    }

    return window;
  }
}

class EmbeddedSTFTCalculator {
  EmbeddedSTFTCalculator(this.stftCalculator);

  final STFTCalculator stftCalculator;

  late final stft = stftCalculator.stft;
  late final window = stftCalculator.window;

  late final chunkSize = stftCalculator.chunkSize;
  late final chunkStride = stftCalculator.chunkStride;

  double deltaTime(int sampleRate) => stftCalculator.deltaTime(sampleRate);
}

class EmbeddedReassignmentCalculator {
  EmbeddedReassignmentCalculator(this.reassignmentCalculator);

  final ReassignmentCalculator reassignmentCalculator;

  late final stft = reassignmentCalculator.stft;
  late final window = reassignmentCalculator.window;
  late final isReassignTime = reassignmentCalculator.isReassignTime;
  late final isReassignFrequency = reassignmentCalculator.isReassignFrequency;
  late final scalar = reassignmentCalculator.scalar;

  late final chunkSize = reassignmentCalculator.chunkSize;
  late final chunkStride = reassignmentCalculator.chunkStride;

  double deltaTime(int sampleRate) =>
      reassignmentCalculator.deltaTime(sampleRate);

  (List<Point> points, Magnitudes magnitudes) reassign(
    AudioData data, [
    bool flush = true,
  ]) =>
      reassignmentCalculator.reassign(data, flush);
}
