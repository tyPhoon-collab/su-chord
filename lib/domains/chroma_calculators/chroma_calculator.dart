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

class HasSTFTCalculatorMethodChained {
  HasSTFTCalculatorMethodChained(this.stftCalculator);

  final STFTCalculator stftCalculator;

  late final stft = stftCalculator.stft;
  late final window = stftCalculator.window;

  int get chunkSize => stftCalculator.chunkSize;

  int get chunkStride => stftCalculator.chunkStride;

  double deltaTime(int sampleRate) => stftCalculator.deltaTime(sampleRate);
}

class ReassignmentCalculator extends HasSTFTCalculatorMethodChained {
  ReassignmentCalculator(
    super.stftCalculator, {
    this.isReassignTime = false,
    this.isReassignFrequency = true,
    this.scalar = MagnitudeScalar.none,
    this.aMin = 1e-5,
  }) {
    _setUpDerivativeSTFT();
    _setUpTimeSTFT();
  }

  void _setUpDerivativeSTFT() {
    if (isReassignFrequency) {
      final windowD = Float64List.fromList(
        window
            .mapIndexed((i, data) => data - (i > 0 ? window[i - 1] : 0.0))
            .toList(),
      );
      stftD = STFT(chunkSize, windowD);
    }
  }

  void _setUpTimeSTFT() {
    if (isReassignTime) {
      final windowT = Float64List.fromList(
        window.mapIndexed((i, data) => data * (i - chunkSize / 2)).toList(),
      );

      stftT = STFT(chunkSize, windowT);
    }
  }

  final MagnitudeScalar scalar;
  final bool isReassignTime;
  final bool isReassignFrequency;
  final double aMin;

  STFT? stftD;
  STFT? stftT;

  ///デバッグのしやすさとモジュール強度を考慮して
  ///ヒストグラム化する関数と再割り当てする関数を分ける
  (List<Point> points, Magnitudes magnitudes) reassign(AudioData data,
      [bool flush = true]) {
    final Magnitudes magnitudes = [];

    final s = <Float64x2List>[];
    late final sD = <Float64x2List>[];
    late final sT = <Float64x2List>[];

    void sCallback(Float64x2List freq) {
      final f = freq.discardConjugates();
      magnitudes.add(scalar(f.magnitudes()));
      s.add(f.sublist(0));
    }

    void sDCallback(Float64x2List freq) {
      sD.add(freq.discardConjugates().sublist(0));
    }

    void sTCallback(Float64x2List freq) {
      sT.add(freq.discardConjugates().sublist(0));
    }

    stft.stream(data.buffer, sCallback, chunkStride);
    stftD?.stream(data.buffer, sDCallback, chunkStride);
    stftT?.stream(data.buffer, sTCallback, chunkStride);

    if (flush) {
      stft.flush(sCallback);
      stftD?.flush(sDCallback);
      stftT?.flush(sTCallback);
    }

    final points = <Point>[];
    final sr = data.sampleRate;
    final dt = (chunkStride == 0 ? chunkSize : chunkStride) / sr;
    final df = sr / chunkSize;

    for (int i = 0; i < s.length; ++i) {
      for (int j = 0; j < s[i].length; ++j) {
        if (magnitudes[i][j] < aMin) continue;

        late final isZero = s[i][j] == Float64x2.zero();

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

class HasReassignmentCalculatorMethodChained {
  HasReassignmentCalculatorMethodChained(this.reassignmentCalculator);

  final ReassignmentCalculator reassignmentCalculator;

  late final stft = reassignmentCalculator.stft;
  late final window = reassignmentCalculator.window;
  late final isReassignTime = reassignmentCalculator.isReassignTime;
  late final isReassignFrequency = reassignmentCalculator.isReassignFrequency;
  late final scalar = reassignmentCalculator.scalar;

  int get chunkSize => reassignmentCalculator.chunkSize;

  int get chunkStride => reassignmentCalculator.chunkStride;

  double deltaTime(int sampleRate) =>
      reassignmentCalculator.deltaTime(sampleRate);
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
