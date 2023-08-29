import '../utils/loader.dart';
import '../utils/tree.dart';
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

typedef DBSearchTrees = Iterable<TreeNode<DegreeChord>>;

///論文を元にDBの構築をし、コードの絞り込みを実装する
///計算量削減と重複を最小限に抑えるために探索木により定義する
///また、探索木の構築は特定のフォーマットに従ったファイルから行い
///再帰的にDBに当てはまりうるコード群を取得し、論理積をとる
class ChordProgressionDBChordSelector implements ChordSelectable {
  ChordProgressionDBChordSelector({required this.progressions});

  static Future<Iterable<DegreeChordProgression>> load(String path) async {
    final csv = await SimpleCSVLoader(path: path).load();
    return csv.map((e) {
      final row = e.whereType<String>().toList();
      return DegreeChordProgression.fromCSVRow(row);
    });
  }

  final Iterable<DegreeChordProgression> progressions;

  late final DBSearchTrees _trees = _buildTrees();
  late final int _maxProgressionLength =
      progressions.fold(0, (len, e) => len < e.length ? e.length : len);

  @override
  Chord? select(Iterable<Chord> possibleChords, ChordProgression progression) {
    if (possibleChords.length <= 1) return possibleChords.firstOrNull;
    final len = progression.length;
    if (len > _maxProgressionLength) {
      progression = progression.cut(len - _maxProgressionLength);
    }
    final chords = _select(progression);
  }

  Set<Chord> _select(ChordProgression progression) {
    for (final root in _trees) {
      for (final chord in progression) {
        //コードタイプとテンションが等しい時、ディグリーネームを具象化し候補和音群に追加
        if (chord != null && root.value.baseEqual(chord)) {}
      }
    }
    return {};
  }

  DBSearchTrees _buildTrees() {
    final Map<DegreeChord, TreeNode<DegreeChord>> nodes = {};
    final DBSearchTrees trees = [];

    for (final progression in progressions) {
      final firstChord = progression.first!;
      var node = nodes.putIfAbsent(firstChord, () => TreeNode(firstChord));
      for (final chord in progression.toList().sublist(1)) {
        node = node.putChildIfAbsent(chord!, () => TreeNode(chord));
      }
    }

    return trees;
  }
}
