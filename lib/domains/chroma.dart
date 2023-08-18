import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/widgets.dart';

import '../config.dart';
import '../utils/formula.dart';
import '../utils/loader.dart';
import '../utils/plot.dart';
import 'chord.dart';
import 'equal_temperament.dart';

typedef Magnitudes = List<Float64List>;

///クロマ同士の計算などの利便化のために、クラス化する
@immutable
class Chroma {
  Chroma(this.values);

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

  late final normalized = values.map((e) => e / l2norm).toList();
  late final l2norm = sqrt(values.fold(0.0, (sum, e) => sum + e * e));

  double cosineSimilarity(Chroma other) {
    assert(values.length == other.values.length);
    double sum = 0;
    for (int i = 0; i < values.length; ++i) {
      sum += normalized[i] * other.normalized[i];
    }
    return sum;
  }
}

///必ず12個の特徴量をもったクロマ
class PCP extends Chroma {
  PCP(super.values) : assert(values.length == 12);

  factory PCP.fromNotes(Notes notes) {
    final values = List.filled(12, 0.0);

    final indexes = notes.map((e) => Note.C.degreeTo(e));
    for (final i in indexes) {
      values[i] = 1;
    }

    return PCP(values);
  }

  static final zero = PCP(List.filled(12, 0));
}

abstract interface class ChromaCalculable {
  List<Chroma> chroma(AudioData data);
}

/// a / b in complex
Float64x2 _div(Float64x2 a, Float64x2 b) {
  final c = b.x * b.x + b.y * b.y;
  return Float64x2((a.x * b.x + a.y * b.y) / c, (a.y * b.x - a.x * b.y) / c);
}

class STFTCalculator {
  STFTCalculator.hanning({this.chunkSize = Config.chunkSize, int? chunkStride})
      : chunkStride = chunkStride ?? chunkSize ~/ 4,
        window = Window.hanning(chunkSize) {
    stft = STFT(chunkSize, window);
  }

  final Float64List window;
  late final STFT stft;
  final int chunkSize;
  final int chunkStride;

  Magnitudes magnitudes = [];
}

class CombFilterChromaCalculator extends STFTCalculator
    implements ChromaCalculable {
  CombFilterChromaCalculator({MusicalScale? lowest, this.perOctave = 7})
      : lowest = lowest ?? MusicalScale.C1,
        super.hanning();

  final MusicalScale lowest;
  final int perOctave;

  @override
  List<Chroma> chroma(AudioData data) {
    stft.run(
      data.buffer,
      (freq) {
        magnitudes.add(freq.discardConjugates().magnitudes());
      },
      chunkStride,
    );

    final df = data.sampleRate / chunkSize;
    return magnitudes.map((e) => _getCombFilterChroma(e, df)).toList();
  }

  Chroma _getCombFilterChroma(Float64List magnitude, double df) {
    return Chroma(
      List.generate(
          12, (i) => _getCombFilterPower(magnitude, df, lowest.to(i))),
    );
  }

  double _getCombFilterPower(
      Float64List magnitude, double df, MusicalScale lowest) {
    double sum = 0;
    for (int i = 0; i < perOctave; ++i) {
      final scale = lowest.to(i * 12);
      final closure = normalDistributionClosure(scale.hz, scale.hz / 24);
      sum += magnitude.mapIndexed((j, e) => closure(j * df) * e).sum;
    }

    return sum;
  }
}

class ReassignmentChromaCalculator extends STFTCalculator
    implements ChromaCalculable {
  ReassignmentChromaCalculator(
      {super.chunkSize = Config.chunkSize,
      super.chunkStride,
      MusicalScale? lowest,
      this.perOctave = 7})
      : lowest = lowest ?? MusicalScale.C1,
        super.hanning() {
    final windowD = Float64List.fromList(window
        .mapIndexed((i, data) => data - (i > 0 ? window[i - 1] : 0.0))
        .toList());
    final windowT = Float64List.fromList(
        window.mapIndexed((i, data) => data * (i - chunkSize / 2)).toList());

    stftD = STFT(chunkSize, windowD);
    stftT = STFT(chunkSize, windowT);
  }

  final MusicalScale lowest;
  final int perOctave;
  late final STFT stftD;
  late final STFT stftT;

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
    binX = _createBinX(data.duration, interval);
    histogram2d = WeightedHistogram2d.from(points, binX: binX, binY: binY);
    return histogram2d!.values.map(_fold).toList();
  }

  List<double> _createBinX(double duration, double interval) {
    final length = (duration / interval).ceil() + 1;
    return List.generate(
        length, (i) => i == length - 1 ? duration : i * interval);
  }

  PCP _fold(List<double> value) {
    final offset = equalTemperament.lowestScale.degreeTo(lowest);
    return PCP(List.generate(12, (i) {
      double sum = 0;

      //7オクターブ分折りたたむC1-B7
      for (var j = 0; j < perOctave; j++) {
        final index = offset + i + 12 * j;
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
