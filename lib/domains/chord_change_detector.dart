import '../utils/formula.dart';
import 'chroma.dart';

abstract interface class ChordChangeDetectable {
  List<Chroma> reduce(List<Chroma> chroma);
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
