import 'chord.dart';
import 'chord_progression.dart';

abstract interface class ChordSelectable {
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression);
}

class FirstChordSelector implements ChordSelectable {
  @override
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression) {
    return possibleChords.firstOrNull;
  }
}

///論文を元にDBの構築をし、コードの絞り込みを実装する
///計算量削減と重複を最小限に抑えるために探索木により定義する
///また、探索木の構築は特定のフォーマットに従ったファイルから行い
///再帰的にDBに当てはまりうるコード群を取得し、論理積をとる
class ChordProgressionDBChordSelector implements ChordSelectable {
  const ChordProgressionDBChordSelector({required this.path});

  final String path;
  
  @override
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression) {
    // TODO: implement select
    throw UnimplementedError();
  }
}
