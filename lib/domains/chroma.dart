import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/widgets.dart';

import '../utils/formula.dart';
import '../utils/histogram.dart';
import '../utils/loader/audio.dart';
import '../utils/measure.dart';
import 'chord.dart';
import 'equal_temperament.dart';

typedef Magnitudes = List<Float64List>;
typedef Spectrogram = List<Float64x2List>;

abstract interface class ChromaCalculable {
  List<Chroma> call(AudioData data, [bool flush = true]);
}

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

  double get max => _values[maxIndex];

  late final Iterable<int> maxSortedIndexes =
      _values.sorted((a, b) => b.compareTo(a)).map((e) => _values.indexOf(e));

  late final normalized = Chroma(_values.map((e) => e / l2norm).toList());
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

abstract class MagnitudesChromaCalculator extends STFTCalculator
    implements ChromaCalculable {
  MagnitudesChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    this.scalar = MagnitudeScalar.none,
  }) : super.hanning();

  final MagnitudeScalar scalar;

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    final magnitudes = [];
    void callback(Float64x2List freq) =>
        magnitudes.add(freq.discardConjugates().magnitudes());
    stft.stream(data.buffer, callback, chunkStride);
    if (flush) stft.flush(callback);

    return magnitudes
        .map((e) => chromaFromMagnitudes(scalar(e), data))
        .toList();
  }

  Chroma chromaFromMagnitudes(Float64List magnitude, AudioData data);
}

class CombFilterContext {
  const CombFilterContext({
    this.stdDevCoefficient = 1 / 72,
  });

  final double stdDevCoefficient;
}

class CombFilterChromaCalculator extends MagnitudesChromaCalculator {
  CombFilterChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    this.lowest = MusicalScale.C1,
    this.context = const CombFilterContext(),
    this.perOctave = 7,
    super.scalar,
  }) : super();

  final MusicalScale lowest;
  final CombFilterContext context;
  final int perOctave;

  @override
  Chroma chromaFromMagnitudes(Float64List magnitude, AudioData data) {
    return Chroma(
      List.generate(
        12,
        (i) => _getCombFilterPower(
          magnitude,
          data.sampleRate,
          lowest.transpose(i),
        ),
      ),
    ).shift(-lowest.note.degreeTo(Note.C));
  }

  ///各音階ごとに正規分布によるコムフィルタを適用した結果を取得する
  ///正規分布の平均値は各音階の周波数、標準偏差は[CombFilterContext]の値を参照する
  double _getCombFilterPower(
      Float64List magnitude, int sampleRate, MusicalScale lowest) {
    double sum = 0;
    final sr = sampleRate.toDouble();
    for (int i = 0; i < perOctave; ++i) {
      final scale = lowest.transpose(i * 12);
      final hz = scale.toHz();
      final mean = hz;
      // final stdDev = scale.hz / 24;
      // 従来法の標準偏差では、周りが大きくなりすぎる
      // 従来法のコードを見ても、論文に準拠していない。よくわからない値を使用している
      final stdDev = hz * context.stdDevCoefficient;
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

///再割り当て法を元にクロマを算出する
///時間軸方向の再割り当てはリアルタイム処理の場合、先読みが必要になるので一旦しない前提
class ReassignmentChromaCalculator extends STFTCalculator
    with Measure
    implements ChromaCalculable {
  ReassignmentChromaCalculator({
    super.chunkSize,
    super.chunkStride,
    this.lowest = MusicalScale.C1,
    this.perOctave = 7,
    this.scalar = MagnitudeScalar.none,
  }) : super.hanning() {
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
  final MagnitudeScalar scalar;
  late final STFT stftD;
  late final STFT stftT;

  WeightedHistogram2d? histogram2d;
  double dt = 0;
  double df = 0;
  Bin binX = [];

  late final Bin binY =
      equalTemperamentBin(lowest, lowest.transpose(12 * perOctave));

  @override
  List<Chroma> call(AudioData data, [bool flush = true]) {
    final (points, magnitudes) =
        measure('reassign', () => reassign(data, flush));
    binX = List.generate(magnitudes.length + 1, (i) => i * dt);
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
  (List<Point> points, Magnitudes magnitudes) reassign(AudioData data,
      [bool flush = true]) {
    final Magnitudes magnitudes = [];

    startMeasuring();
    final s = <Float64x2List>[];
    final sD = <Float64x2List>[];
    final sT = <Float64x2List>[];

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
    stftD.stream(data.buffer, sDCallback, chunkStride);
    stftT.stream(data.buffer, sTCallback, chunkStride);

    if (flush) {
      stft.flush(sCallback);
      stftD.flush(sDCallback);
      stftT.flush(sTCallback);
    }

    stopMeasuring('3 times stft');

    startMeasuring();

    final points = <Point>[];
    final sr = data.sampleRate;
    dt = (chunkStride == 0 ? chunkSize : chunkStride) / sr;
    df = sr / chunkSize;

    for (int i = 0; i < s.length; ++i) {
      for (int j = 0; j < s[i].length; ++j) {
        if (magnitudes[i][j] < 1e-3 || s[i][j] == Float64x2.zero()) continue;

        points.add(Point(
          x: i * dt,
          // x: i * dt + complexDivision(sT[i][j], s[i][j]).x / sr,
          y: j * df - complexDivision(sD[i][j], s[i][j]).y * (0.5 * sr / pi),
          weight: magnitudes[i][j],
        ));
      }
    }

    stopMeasuring('create reassign points');

    return (points, magnitudes);
  }
}
