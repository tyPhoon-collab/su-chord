import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../annotation.dart';
import '../chord.dart';
import '../chroma.dart';
import '../equal_temperament.dart';
import '../score_calculator.dart';

abstract interface class ChromaChordChangeDetectable {
  List<Slice> call(List<Chroma> chroma);
}

///渡されたクロマのリストをスライスして平均値のリストを返す
///[slices]を渡さないときは全ての平均をとる
List<Chroma> average(List<Chroma> source, [List<Slice>? slices]) {
  slices ??= [Slice(0, source.length)];

  final averages = <Chroma>[];

  for (final slice in slices) {
    var end = slice.end;
    if (end > source.length) {
      end = source.length;
      debugPrint(
          'end is over length, end: ${slice.end}, length: ${source.length}');
    }
    final sliced = source.sublist(slice.start, end);
    final sum = sliced.reduce((a, b) => a + b);
    averages.add(sum / slice.size);
  }

  return averages;
}

class FrameChordChangeDetector implements ChromaChordChangeDetectable {
  const FrameChordChangeDetector();

  @override
  List<Slice> call(List<Chroma> chroma) {
    return List.generate(
      chroma.length,
      (i) => Slice(i, i + 1),
    );
  }
}

///秒数によってコード区間を設定する
class IntervalChordChangeDetector implements ChromaChordChangeDetectable {
  IntervalChordChangeDetector(
      {required this.interval, required this.deltaTime}) {
    _intervalSeconds = interval.inMicroseconds / 1000000;
    if (_intervalSeconds <= deltaTime) {
      debugPrint('Interval is less than dt. This filter will be ignored');
    }
  }

  @override
  String toString() => 'interval HCDF $interval';

  final double deltaTime;
  final Duration interval;
  late final double _intervalSeconds;

  @override
  List<Slice> call(List<Chroma> chroma) {
    if (_intervalSeconds <= deltaTime) {
      return const FrameChordChangeDetector().call(chroma);
    }

    final slices = <Slice>[];
    double accumulatedTime = 0;
    int seek = 0;
    int count = 0;

    for (; count < chroma.length; count++) {
      accumulatedTime += deltaTime;

      if (accumulatedTime >= _intervalSeconds) {
        slices.add(Slice(seek, count + 1));
        accumulatedTime -= _intervalSeconds;
        seek = count + 1;
      }
    }

    // ignore. 3.6, dt:2 -> 2. not 2, 1.6
    // if (seek < count) {
    //   slices.add(Slice(seek, count));
    // }

    return slices;
  }
}

///無音区間があれば、そこをコード区間の区切りとする
///onPowerは無音でない部分を更に分割する[ChromaChordChangeDetectable]を指定する
class PowerThresholdChordChangeDetector implements ChromaChordChangeDetectable {
  const PowerThresholdChordChangeDetector(
    this.threshold, {
    this.onPower,
  });

  final double threshold;
  final ChromaChordChangeDetectable? onPower;

  @override
  String toString() => 'threshold HCDF $threshold';

  @override
  List<Slice> call(List<Chroma> chroma) {
    final slices = <Slice>[];
    int? seek;
    int count = 0;

    for (; count < chroma.length; count++) {
      if (chroma[count].l2norm < threshold) {
        if (seek != null) {
          add(slices, chroma, seek, count);
          seek = null;
        }
      } else {
        seek ??= count;
      }
    }

    if (seek != null && seek < count) {
      add(slices, chroma, seek, count);
    }

    return slices;
  }

  void add(List<Slice> slices, List<Chroma> chroma, int seek, int count) {
    if (onPower == null) {
      slices.add(Slice(seek, count));
    } else {
      slices.addAll(onPower!(chroma.sublist(seek, count)).map((e) => e + seek));
    }
  }
}

///少ないコードタイプで推定することで、コード区間を概算する
class TriadChordChangeDetector implements ChromaChordChangeDetectable {
  TriadChordChangeDetector({
    // this.lookaheadSize = 5,
    this.scoreCalculator = const ScoreCalculator.cosine(),
  });

  final _templates = [
    for (final root in Note.sharpNotes)
      for (final type in ChordType.triads)
        Chord.fromType(type: type, root: root)
  ];

  final ScoreCalculator scoreCalculator;

  // final int lookaheadSize;

  @override
  String toString() => 'triad HCDF';

  @override
  List<Slice> call(List<Chroma> chroma) {
    final chords = chroma
        .map((e) => maxBy(_templates, (t) => scoreCalculator(e, t.unitPCP))!)
        .toList();

    final slices = <Slice>[];
    int seek = 0;
    int count = 1;

    for (; count < chroma.length; count++) {
      if (chords[count - 1] != chords[count]) {
        slices.add(Slice(seek, count));
        seek = count;
      }
    }

    if (seek < count) {
      slices.add(Slice(seek, count));
    }

    return slices;
  }
}

class PreFrameCheckChordChangeDetector implements ChromaChordChangeDetectable {
  const PreFrameCheckChordChangeDetector({
    required this.scoreCalculator,
    required this.threshold,
  });

  const PreFrameCheckChordChangeDetector.cosine(this.threshold)
      : assert(0 <= threshold && threshold <= 1, 'threshold MUST BE [0, 1]'),
        scoreCalculator = const ScoreCalculator.cosine();

  final double threshold;
  final ScoreCalculator scoreCalculator;

  @override
  String toString() => '$scoreCalculator HCDF $threshold';

  @override
  List<Slice> call(List<Chroma> chroma) {
    final slices = <Slice>[];
    int? seek;
    int count = 1;

    for (; count < chroma.length; count++) {
      final score = scoreCalculator(chroma[count], chroma[count - 1]);
      // debugPrint(score.toStringAsFixed(3));

      if (score < threshold) {
        if (seek != null) {
          slices.add(Slice(seek, count));
          seek = null;
        }
      } else {
        seek ??= count - 1;
      }
    }

    if (seek != null && seek < count) {
      slices.add(Slice(seek, count));
    }

    return slices;
  }
}
