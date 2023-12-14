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

///STFTに必要な変数群を定義したクラス
///継承して使用する
///実際にSTFTの計算をする際は、パッケージの実装の都合上、stft変数から行うので
///STFTの計算をする関数自体はこのクラスにはない
class STFTCalculator {
  STFTCalculator.hanning({
    this.chunkSize = 2048,
    this.chunkStride = 1024,
  }) : window = Window.hanning(chunkSize) {
    stft = STFT(chunkSize, window);
  }

  final Float64List window;
  late final STFT stft;
  final int chunkSize;
  final int chunkStride;

  double deltaTime(int sampleRate) =>
      (chunkStride == 0 ? chunkSize : chunkStride) / sampleRate;

  double deltaFrequency(int sampleRate) => sampleRate / chunkSize;
}

class ReassignmentCalculator extends STFTCalculator {
  ReassignmentCalculator.hanning({
    super.chunkSize,
    super.chunkStride,
    this.isReassignTime = false,
    this.isReassignFrequency = true,
    this.scalar = MagnitudeScalar.none,
    this.aMin = 1e-5,
  }) : super.hanning() {
    if (isReassignFrequency) {
      final windowD = Float64List.fromList(
        window
            .mapIndexed((i, data) => data - (i > 0 ? window[i - 1] : 0.0))
            .toList(),
      );
      stftD = STFT(chunkSize, windowD);
    }

    if (isReassignTime) {
      final windowT = Float64List.fromList(
        window.mapIndexed((i, data) => data * (i - chunkSize / 2)).toList(),
      );

      stftT = STFT(chunkSize, windowT);
    }
  }

  STFT? stftD;
  STFT? stftT;
  final MagnitudeScalar scalar;
  final bool isReassignTime;
  final bool isReassignFrequency;
  final double aMin;

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
        if (magnitudes[i][j] < aMin || s[i][j] == Float64x2.zero()) continue;

        points.add(Point(
          x: isReassignTime
              ? i * dt + complexDivision(sT[i][j], s[i][j]).x / sr
              : i * dt,
          y: isReassignFrequency
              ? j * df - complexDivision(sD[i][j], s[i][j]).y * (0.5 * sr / pi)
              : j * df,
          weight: magnitudes[i][j],
        ));
      }
    }

    return (points, magnitudes);
  }
}
