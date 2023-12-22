import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';

import '../utils/loaders/csv.dart';
import '../utils/tree.dart';
import 'chord.dart';
import 'chord_progression.dart';
import 'equal_temperament.dart';

abstract interface class ChordSelectable {
  ChordProgression<Chord> call(ChordProgression<Chord> progression);
}

typedef DBSearchTrees = Map<Chord, TreeNode<Chord>>;

///DBファイルからコードの絞り込みを実装する
///計算量削減と重複を最小限に抑えるために探索木により定義する
///また、探索木の構築は特定のフォーマットに従ったファイルから行い
///再帰的にDBに当てはまりうるコード群を取得し、論理積をとる
class ChordProgressionDBChordSelector implements ChordSelectable {
  ChordProgressionDBChordSelector({required this.progressions});

  ChordProgressionDBChordSelector.fromCSV(CSV csv) : progressions = parse(csv);

  static Iterable<ChordProgression<DegreeChord>> parse(CSV csv) {
    return csv.map((e) {
      final row = e.whereType<String>().toList();
      return ChordProgression.fromDegreeChordRow(row);
    });
  }

  final Iterable<ChordProgression<DegreeChord>> progressions;

  late final DBSearchTrees _trees = _buildTrees();
  late final int _maxProgressionLength =
      progressions.fold(0, (len, e) => len < e.length ? e.length : len);

  @override
  String toString() => 'select by db';

  @override
  ChordProgression<Chord> call(ChordProgression<Chord> progression) {
    final cells = <ChordCell<Chord>>[];

    for (final cell in progression) {
      if (cell is MultiChordCell<Chord>) {
        cells.add(cell.copyWith(
          chord: _selectChord(
            cell.chords,
            cells.map((e) => e.chord).nonNulls,
          ),
        ));
      } else {
        debugPrint('cell is not MultiChordCell, ignored selection');
      }
    }

    return ChordProgression(cells);
  }

  ///[progression]は直前までのコード進行
  Chord? _selectChord(List<Chord> chords, Iterable<Chord> progression) {
    final first = chords.firstOrNull;

    if (chords.length <= 1) return first;

    //DBの最長進行でカットする
    final len = progression.length;
    if (len > _maxProgressionLength) {
      progression = progression.skip(len - _maxProgressionLength);
    }

    final possibleChords = _findMatchingChordsInDB(progression);
    return possibleChords.firstWhereOrNull((e) => chords.contains(e)) ?? first;
  }

  ///再帰的にコード進行を辿ってDBを参照する
  ///空のコード進行の場合はDBの最初のコードの全てが返される
  ///DartのSetは順番を持つため、再帰の順番に気をつければ、優先度は長い進行に適合するコードになる
  Set<Chord> _findMatchingChordsInDB(Iterable<Chord> progression) {
    if (progression.isEmpty) return _trees.keys.toSet();

    final root = _trees[progression.first];
    final withoutFirstProgression = progression.skip(1);

    if (root == null) return _findMatchingChordsInDB(withoutFirstProgression);

    var node = root;

    for (final chord in withoutFirstProgression) {
      final n = node.getChild(chord);
      if (n == null) return _findMatchingChordsInDB(withoutFirstProgression);
      node = n;
    }
    return {
      ...node.childrenValues,
      ..._findMatchingChordsInDB(withoutFirstProgression)
    };
  }

  DBSearchTrees _buildTrees() {
    final DBSearchTrees nodes = {};

    for (final degreeChordProgression in progressions) {
      for (int i = 0; i < Note.length; i++) {
        final progression = degreeChordProgression.toChord(Note.sharpNotes[i]);
        final firstChord = progression.first.chord!;
        var node = nodes.putIfAbsent(firstChord, () => TreeNode(firstChord));
        for (final chord in progression.toChordList().skip(1)) {
          node = node.putChildIfAbsent(chord!, () => TreeNode(chord));
        }
      }
    }

    return nodes;
  }
}

///Am7b5とCm6などの関係は同じ構成音であるため、PCPだけでは区別ができない
///また、平均化されたPCPをテンプレートに使用する際に、b5の影響で誤分類が多い
///そのため、m7b5系に対して、一般に高確率でマイナーが選ばれる条件をもとに絞り込みを行う
// ignore: camel_case_types
class FlatFiveChordSelector implements ChordSelectable {
  const FlatFiveChordSelector();

  @override
  ChordProgression<Chord> call(ChordProgression<Chord> progression) {
    final cells = <ChordCell<Chord>>[];

    for (int i = 0; i < progression.length - 1; i++) {
      var cell = progression[i];
      final nextChord = progression[i + 1].chord;

      if (nextChord != null &&
          cell is MultiChordCell<Chord> &&
          cell.chords.length > 1) {
        for (final chord in cell.chords) {
          final degreeIndex = chord.root.positiveDegreeIndexTo(nextChord.root);

          if (chord.type case ChordType.minorSeventhFlatFive) {
            //minor II-V
            //半音下
            if (degreeIndex == NamedDegree.P4.degreeIndex ||
                degreeIndex == NamedDegree.M7.degreeIndex) {
              cell = cell.copyWith(chord: chord);
              break;
            }
          }
        }
      }

      cells.add(cell);
    }

    cells.add(progression.last);

    return ChordProgression(cells);
  }
}
