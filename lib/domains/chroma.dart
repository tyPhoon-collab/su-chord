import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/widgets.dart';

import '../config.dart';
import '../utils/formula.dart';
import '../utils/loader.dart';
import '../utils/measure.dart';
import '../utils/plot.dart';
import 'chord.dart';
import 'equal_temperament.dart';

typedef Magnitudes = List<Float64List>;

///クロマ同士の計算などの利便化のために、クラス化する
@immutable
class Chroma extends Iterable<double> {
  Chroma(this._values);

  factory Chroma.zero(int length) => Chroma(List.filled(length, 0.0));

  final List<double> _values;

  static final empty = Chroma(const []);

  int get maxIndex {
    var max = _values[0];
    var maxIndex = 0;
    for (var i = 1; i < _values.length; i++) {
      if (_values[i] > max) {
        max = _values[i];
        maxIndex = i;
      }
    }

    return maxIndex;
  }

  double get max => this[maxIndex];

  late final Iterable<int> maxSortedIndex =
      _values.sorted((a, b) => b.compareTo(a)).map((e) => _values.indexOf(e));

  late final normalized = _values.map((e) => e / l2norm).toList();
  late final l2norm = sqrt(_values.fold(0.0, (sum, e) => sum + e * e));

  double cosineSimilarity(Chroma other) {
    assert(_values.length == other._values.length);
    double sum = 0;
    for (int i = 0; i < _values.length; ++i) {
      sum += normalized[i] * other.normalized[i];
    }
    return sum;
  }

  Chroma shift(int num) {
    if (num == 0) return this;
    final length = _values.length;
    num %= length; // 配列の長さより大きい場合は余りを取る
    final rotated = _values.sublist(length - num)
      ..addAll(_values.sublist(0, length - num));
    return Chroma(rotated);
  }

  Chroma operator +(Chroma other) {
    assert(_values.length == other._values.length,
        'source: ${_values.length}, other: ${other._values.length}');
    return Chroma(
        List.generate(_values.length, (i) => _values[i] + other._values[i]));
  }

  Chroma operator /(num denominator) {
    return Chroma(_values.map((e) => e / denominator).toList());
  }

  double operator [](int index) => _values[index];

  @override
  Iterator<double> get iterator => _values.iterator;

  @override
  String toString() {
    return _values.map((e) => e.toStringAsFixed(3)).join(', ');
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

class STFTCalculator {
  STFTCalculator.hanning({
    this.chunkSize = Config.chunkSize,
    this.chunkStride = Config.chunkStride,
  }) : window = Window.hanning(chunkSize) {
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
  CombFilterChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    MusicalScale? lowest,
    this.perOctave = 7,
  })  : lowest = lowest ?? MusicalScale.C1,
        super.hanning();

  final MusicalScale lowest;
  final int perOctave;

  @override
  List<Chroma> chroma(AudioData data) {
    magnitudes = [];
    stft.run(
      data.buffer,
      (freq) {
        magnitudes.add(freq.discardConjugates().magnitudes());
      },
      chunkStride,
    );

    return magnitudes
        .map((e) => _getCombFilterChroma(e, data.sampleRate))
        .toList();
  }

  Chroma _getCombFilterChroma(Float64List magnitude, int sampleRate) {
    return Chroma(List.generate(12,
            (i) => _getCombFilterPower(magnitude, sampleRate, lowest.to(i))))
        .shift(-lowest.note.degreeTo(Note.C));
  }

  double _getCombFilterPower(
      Float64List magnitude, int sampleRate, MusicalScale lowest) {
    double sum = 0;
    final sr = sampleRate.toDouble();
    for (int i = 0; i < perOctave; ++i) {
      final scale = lowest.to(i * 12);
      final mean = scale.hz;
      // final stdDev = scale.hz / 24;
      // 従来法の標準偏差では、周りが大きくなりすぎる
      // 従来法のコードを見ても、論文に準拠していない。よくわからない値を使用している
      // 2σで考えてみる
      // final stdDev = scale.hz / 48;
      // 3σで考えてみる
      final stdDev = scale.hz / 72;
      // 正規分布の端っこの方は値がほとんど0であるため、計算量削減のため畳み込む範囲を指定する
      final range = 4 * stdDev;
      final closure = normalDistributionClosure(mean, stdDev);
      final startIndex = stft.indexOfFrequency(mean - range, sr).round();
      final endIndex = stft.indexOfFrequency(mean + range, sr).round();

      sum += magnitude
          .sublist(startIndex, endIndex)
          .mapIndexed((j, e) => closure(stft.frequency(j + startIndex, sr)) * e)
          .sum;
    }

    return sum;
  }
}

class ReassignmentChromaCalculator extends STFTCalculator
    with Measure
    implements ChromaCalculable {
  ReassignmentChromaCalculator(
      {super.chunkSize,
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

  late final Bin binY = equalTemperamentBin(lowest, lowest.to(12 * perOctave));

  @override
  List<Chroma> chroma(AudioData data) {
    magnitudes = [];
    final points = measure('reassign', () => reassign(data));
    binX = List.generate(magnitudes.length, (i) => i * dt)..add(data.duration);
    histogram2d = measure(
      'hist2d',
      () => WeightedHistogram2d.from(
        points,
        binX: binX,
        binY: binY,
      ),
    );
    printMeasuredResult();
    return histogram2d!.values.map(_fold).toList();
  }

  Chroma _fold(List<double> value) {
    return PCP(List.generate(12, (i) {
      double sum = 0;

      //折りたたむ
      for (var j = 0; j < perOctave; j++) {
        final index = i + 12 * j;
        sum += value[index];
      }
      return sum;
    })).shift(-lowest.note.degreeTo(Note.C));
  }

  ///デバッグのしやすさとモジュール強度を考慮して
  ///ヒストグラム化する関数と再割り当てする関数を分ける
  List<Point> reassign(AudioData data) {
    startMeasuring();
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

    stopMeasuring('3 times stft');

    startMeasuring();

    final points = <Point>[];
    dt = (chunkStride == 0 ? chunkSize : chunkStride) / data.sampleRate;
    df = data.sampleRate / chunkSize;

    for (int i = 0; i < s.length; ++i) {
      for (int j = 0; j < s[i].length; ++j) {
        if (magnitudes[i][j] < 1e-3 || s[i][j] == Float64x2.zero()) continue;

        final x =
            i * dt + complexDivision(sT[i][j], s[i][j]).x / data.sampleRate;
        final y = j * df -
            complexDivision(sD[i][j], s[i][j]).y * (0.5 * data.sampleRate / pi);
        points.add(Point(x: x, y: y, weight: magnitudes[i][j]));
      }
    }

    stopMeasuring('create reassign points');

    return points;
  }
}
