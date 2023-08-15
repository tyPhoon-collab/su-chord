import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/widgets.dart';

import '../config.dart';
import '../utils/loader.dart';
import '../utils/plot.dart';
import 'equal_temperament.dart';

///クロマ同士の計算などの利便化のために、クラス化する
@immutable
class Chroma {
  const Chroma(this.values);

  final List<double> values;

  int maxIndex() {
    var max = values[0];
    var maxIndex = 0;
    for (var i = 1; i < values.length; i++) {
      if (values[i] > max) {
        max = values[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

//TODO オペレーションの追加
}

///必ず12個の特徴量をもったクロマ
class PCP extends Chroma {
  const PCP(super.values) : assert(values.length == 12);

  static final zero = PCP(List.filled(12, 0));
}

abstract interface class ChromaCalculable {
  List<Chroma> chroma(AudioData audioData);
}

/// a / b in complex
Float64x2 _div(Float64x2 a, Float64x2 b) {
  final c = b.x * b.x + b.y * b.y;
  return Float64x2((a.x * b.x + a.y * b.y) / c, (a.y * b.x - a.x * b.y) / c);
}

class ReassignmentChromaCalculator implements ChromaCalculable {
  ReassignmentChromaCalculator(
      {this.chunkSize = Config.chunkSize, int? chunkStride})
      : chunkStride = chunkStride ?? chunkSize ~/ 4 {
    final window = Window.hanning(chunkSize);

    final windowD = Float64List.fromList(window
        .mapIndexed((i, data) => data - (i > 0 ? window[i - 1] : 0.0))
        .toList());
    final windowT = Float64List.fromList(
        window.mapIndexed((i, data) => data * (i - chunkSize / 2)).toList());

    stft = STFT(chunkSize, window);
    stftD = STFT(chunkSize, windowD);
    stftT = STFT(chunkSize, windowT);
  }

  final int chunkSize;
  final int chunkStride;
  late final STFT stft;
  late final STFT stftD;
  late final STFT stftT;

  List<Float64List> magnitudes = [];
  WeightedHistogram2d? histogram2d;
  double dt = 0;
  double df = 0;
  Bin binX = [];

  Bin get binY => equalTemperament.bin;

  final equalTemperament = EqualTemperament();

  @override
  List<Chroma> chroma(AudioData data) {
    const interval = 4.0;

    final points = reassign(data);
    binX = List.generate(
        (data.duration / interval).ceil(), (index) => index * interval);
    binX[binX.length - 1] = data.duration;
    histogram2d = WeightedHistogram2d.from(points, binX: binX, binY: binY);
    return histogram2d!.values.map(_fold).toList();
  }

  PCP _fold(List<double> value) {
    return PCP(List.generate(12, (i) {
      double sum = 0;

      //7オクターブ分折りたたむC1-B7
      for (var j = 0; j < 7; j++) {
        final index = EqualTemperament.binOffsetIndexToC0 + i + 12 * j;
        sum += value[index];
      }
      return sum;
    }));
  }

  ///デバッグのしやすさとモジュール強度を考慮して
  ///ヒストグラム化する関数と再割り当てする関数を分ける
  List<Point> reassign(AudioData data) {
    final s = <Float64x2List>[];

    stft.run(
      data.buffer,
      (freq) {
        final f = freq.discardConjugates();
        s.add(Float64x2List.fromList(f));
        magnitudes.add(f.magnitudes());
      },
      chunkStride,
    );

    final sD = <Float64x2List>[];
    stftD.run(
      data.buffer,
      (freq) {
        sD.add(Float64x2List.fromList(freq));
      },
      chunkStride,
    );

    final sT = <Float64x2List>[];
    stftT.run(
      data.buffer,
      (freq) {
        sT.add(Float64x2List.fromList(freq));
      },
      chunkStride,
    );

    final points = <Point>[];
    dt = chunkStride / data.sampleRate;
    df = data.sampleRate / chunkSize;

    for (int i = 0; i < s.length; ++i) {
      for (int j = 0; j < s[i].length; ++j) {
        if (magnitudes[i][j] == 0 || s[i][j] == Float64x2.zero()) continue;

        final x = i * dt + _div(sT[i][j], s[i][j]).x / data.sampleRate;
        final y =
            j * df - _div(sD[i][j], s[i][j]).y * (0.5 * data.sampleRate / pi);
        points.add(Point(x: x, y: y, weight: magnitudes[i][j]));
      }
    }

    return points;
  }
}
