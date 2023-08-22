import 'package:collection/collection.dart';

import '../utils/formula.dart';
import 'chord.dart';
import 'chroma.dart';
import 'equal_temperament.dart';

abstract interface class ChordChangeDetectable {
  List<Chroma> reduce(List<Chroma> chroma);
}

class PassChordChangeDetector implements ChordChangeDetectable {
  @override
  List<Chroma> reduce(List<Chroma> chroma) => chroma;
}

class IntervalChordChangeDetector implements ChordChangeDetectable {
  IntervalChordChangeDetector({required this.interval, required this.dt});

  final double dt;
  final double interval;

  @override
  List<Chroma> reduce(List<Chroma> chromas) {
    final result = <Chroma>[];

    if (chromas.isEmpty) return result;

    final chromaLength = chromas.first.length;
    var chroma = Chroma.zero(chromaLength);
    double accumulatedTime = 0;
    int accumulatedCount = 0;

    for (int i = 1; i < chromas.length; i++) {
      accumulatedTime += dt;

      if (accumulatedTime >= interval) {
        result.add(chroma / accumulatedCount);
        chroma = Chroma.zero(chromaLength);
        accumulatedTime -= interval;
        accumulatedCount = 0;
      } else {
        chroma += chromas[i];
      }

      accumulatedCount++;
    }

    //コンピュータ特有の誤差を考慮
    if (accumulatedTime + epsilon >= interval) {
      result.add(chroma / accumulatedCount);
    }

    return result;
  }
}

///少ないコードタイプで推定することで、コード区間を概算する
class TriadChordChangeDetector implements ChordChangeDetectable {
  final _templates = [
    for (final root in Note.values)
      for (final type in ChordType.triads)
        Chord.fromType(type: type, root: root)
  ];

  @override
  List<Chroma> reduce(List<Chroma> chroma) {
    final newChromas = <Chroma>[];
    if (chroma.isEmpty) return newChromas;

    final chords = chroma
        .map((e) => maxBy(_templates, (t) => e.cosineSimilarity(t.pcp))!)
        .toList();
    Chord preChord = chords.first;
    int count = 1;
    Chroma c = chroma.first;

    for (int i = 1; i < chroma.length; i++) {
      final chord = chords[i];
      if (chord == preChord) {
        c += chroma[i];
        count++;
      } else {
        newChromas.add(c / count);
        c = Chroma.zero(c.length);
        preChord = chord;
        count = 0;
      }
    }

    if (count != 0) {
      newChromas.add(c / count);
    }

    return newChromas;
  }
}

class DifferenceByThresholdChordChangeDetector
    implements ChordChangeDetectable {
  DifferenceByThresholdChordChangeDetector({required this.threshold});

  final double threshold;

  @override
  List<Chroma> reduce(List<Chroma> chroma) {
    // TODO: implement reduce
    throw UnimplementedError();
  }
}
