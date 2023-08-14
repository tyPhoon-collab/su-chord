import 'dart:math';

import 'plot.dart';

// class MusicalScale {
//   MusicalScale({required this.note, required this.pitch});
//
//   final Note note;
//   final int pitch;
// }
//
// enum Note { A, As, B, C, Cs, D, Ds, E, F, Fs, G, Gs }

class EqualTemperament {
  EqualTemperament({this.lowestHz = 27.5});

  final double lowestHz;

  late final _bin = _buildEqualTemperamentBin();

  Bin get bin => _bin;

  static const binOffsetIndexToC0 = 3;

  Bin _buildEqualTemperamentBin() {
    // ピアノの88鍵の音域の周波数ビンを作成
    // ビン幅は前の音と対象の音の中点 ~ 対象の音と次の音の中点
    // よって、88個の音域のために、90個の音域を最初に計算する

    // 音テーブルの作成。A0~C8
    // 音域の参考サイト: https://tomari.org/main/java/oto.html
    final ratio = pow(2, 1 / 12);
    final hzList = List.generate(90, (i) => lowestHz * pow(ratio, i - 1));

    final bins = <double>[];
    for (var i = 0; i < hzList.length - 1; i++) {
      bins.add((hzList[i] + hzList[i + 1]) / 2);
    }

    return bins;
  }
}
