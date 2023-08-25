import 'chord.dart';
import 'estimate.dart';

abstract interface class ChordSelectable {
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression);
}

class FirstChordSelector implements ChordSelectable {
  @override
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression) {
    return possibleChords.firstOrNull;
  }
}

class ChordProgressionDBChordSelector implements ChordSelectable {
  @override
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression) {
    // TODO: implement select
    throw UnimplementedError();
  }
}
