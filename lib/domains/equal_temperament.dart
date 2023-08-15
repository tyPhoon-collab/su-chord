import 'dart:math';

import '../utils/plot.dart';

class MusicalScale {
  MusicalScale(this.note, this.pitch);

  static final A0 = MusicalScale(Note.A, 0);

  static final ratio = pow(2, 1 / 12);
  static const hzOfA0 = 27.5;

  final Note note;
  final int pitch;

  //計算量削減のために、lateにする
  late final double hz = hzOfA0 * pow(ratio, MusicalScale.A0.degreeTo(this));

  ///ピッチを考慮する度数の差
  ///ex)
  ///A0 -> C1 = 3
  ///C3 -> C4 = 12
  int degreeTo(MusicalScale other) =>
      note.degreeTo(other.note) + 12 * (other.pitch - pitch);
}

enum Note {
  C,
  Cs,
  D,
  Ds,
  E,
  F,
  Fs,
  G,
  Gs,
  A,
  As,
  B;

  ///度数を渡すと新しいNoteを返す
  ///ex)
  ///Note.C.to(2) -> Note.D
  Note to(int degree) => Note.values[(index + degree) % Note.values.length];

  ///度数の差。一般にCが基準であるため、それに準拠
  ///1オクターブで見た時の差とし、音高が高い方が正とする
  ///ex)
  ///D -> A = 7
  ///D -> C = -2
  int degreeTo(Note other) => other.index - index;

  ///負の場合、+12するdegreeTo
  int positiveDegreeTo(Note other) {
    final degree = degreeTo(other);
    return degree.isNegative ? 12 + degree : degree;
  }
}

class EqualTemperament {
  EqualTemperament({MusicalScale? lowestScale})
      : lowestScale = lowestScale ?? MusicalScale.A0;

  final MusicalScale lowestScale;

  late final bin = _buildEqualTemperamentBin();

  Bin _buildEqualTemperamentBin() {
    // ピアノの88鍵の音域の周波数ビンを作成
    // ビン幅は前の音と対象の音の中点 ~ 対象の音と次の音の中点
    // よって、88個の音域のために、90個の音域を最初に計算する

    // 音テーブルの作成。A0~C8
    // 音域の参考サイト: https://tomari.org/main/java/oto.html
    final hzList = List.generate(
        90, (i) => lowestScale.hz * pow(MusicalScale.ratio, i - 1));

    final bins = <double>[];
    for (var i = 0; i < hzList.length - 1; i++) {
      bins.add((hzList[i] + hzList[i + 1]) / 2);
    }

    return bins;
  }
}
