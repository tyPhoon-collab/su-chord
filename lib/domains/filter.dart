import 'package:collection/collection.dart';

import '../utils/formula.dart';
import 'chord.dart';
import 'chroma.dart';
import 'equal_temperament.dart';

abstract interface class ChromaListFilter {
  List<Chroma> filter(List<Chroma> chroma);
}

class ThresholdFilter implements ChromaListFilter {
  ThresholdFilter({required this.threshold});

  final double threshold;

  @override
  List<Chroma> filter(List<Chroma> chroma) =>
      chroma.where((e) => e.max >= threshold).toList();
}

class IntervalChordChangeDetector implements ChromaListFilter {
  IntervalChordChangeDetector({required this.interval, required this.dt});

  final double dt;
  final Duration interval;
  late final _interval = interval.inMilliseconds / 1000;

  @override
  List<Chroma> filter(List<Chroma> chromas) {
    if (chromas.isEmpty) return [];

    final slices = <int>[];
    double accumulatedTime = 0;
    int accumulatedCount = 0;

    for (int i = 0; i < chromas.length; i++) {
      accumulatedTime += dt;
      accumulatedCount++;

      if (accumulatedTime >= _interval) {
        slices.add(accumulatedCount);
        accumulatedTime -= _interval;
        accumulatedCount = 0;
      }
    }

    //コンピュータ特有の誤差を考慮
    if (accumulatedTime + epsilon >= _interval) {
      slices.add(accumulatedCount);
    }

    return _average(chromas, slices);
  }
}

///少ないコードタイプで推定することで、コード区間を概算する
class TriadChordChangeDetector implements ChromaListFilter {
  // TriadChordChangeDetector({this.lookaheadSize = 5});

  final _templates = [
    for (final root in Note.values)
      for (final type in ChordType.triads)
        Chord.fromType(type: type, root: root)
  ];

  // final int lookaheadSize;

  @override
  List<Chroma> filter(List<Chroma> chroma) {
    if (chroma.isEmpty) return [];

    final chords = chroma
        .map((e) => maxBy(_templates, (t) => e.cosineSimilarity(t.pcp))!)
        .toList();

    Chord preChord = chords.first;
    int count = 1;
    final slices = <int>[];

    for (int i = 1; i < chroma.length; i++) {
      final chord = chords[i];

      if (chord != preChord) {
        slices.add(count);
        count = 0;
      }
      preChord = chord;
      count++;
    }

    slices.add(count);

    return _average(chroma, slices);
  }
}

class DifferenceByThresholdChordChangeDetector implements ChromaListFilter {
  DifferenceByThresholdChordChangeDetector({required this.threshold});

  final double threshold;

  @override
  List<Chroma> filter(List<Chroma> chroma) {
    // TODO: implement filter
    throw UnimplementedError();
  }
}

///source [1,2,3,4,5], slices [3,2]
///-> [2, 4.5]
///
///source [1,2,3,4,5,6], slices [3,2]
///-> [2, 4.5]
List<Chroma> _average(List<Chroma> source, List<int> slices) {
  assert(slices.sum <= source.length);

  final averages = <Chroma>[];

  int startIndex = 0;
  for (final sliceSize in slices) {
    final slice = source.sublist(startIndex, startIndex + sliceSize);
    final sum = slice.reduce((a, b) => a + b);
    averages.add(sum / sliceSize);
    startIndex += sliceSize;
  }

  return averages;
}
