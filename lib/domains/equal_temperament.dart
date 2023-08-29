import 'dart:math';

import 'package:flutter/widgets.dart';

import '../utils/histogram.dart';

abstract interface class Transposable<T> {
  T transpose(int degree);
}

@immutable
class MusicalScale implements Transposable<MusicalScale> {
  MusicalScale(this.note, this.pitch);

  static final A0 = MusicalScale(Note.A, 0);
  static final C1 = MusicalScale(Note.C, 1);
  static final E2 = MusicalScale(Note.E, 2);

  static final ratio = pow(2, 1 / 12);
  static const hzOfA0 = 27.5;

  final Note note;
  final int pitch;

  //計算量削減のために、lateにする
  late final double hz = hzOfA0 * pow(ratio, MusicalScale.A0.degreeTo(this));

  ///度数を渡すと新しいMusicalScaleを返す
  @override
  MusicalScale transpose(int degree) {
    if (degree == 0) return this;

    final newNote = note.transpose(degree);
    var newPitch = pitch + degree ~/ 12;
    if (note.degreeTo(newNote).isNegative) {
      newPitch += 1;
    }
    return MusicalScale(newNote, newPitch);
  }

  ///ピッチを考慮する度数の差
  ///ex)
  ///A0 -> C1 = 3
  ///C3 -> C4 = 12
  int degreeTo(MusicalScale other) =>
      note.degreeTo(other.note) + 12 * (other.pitch - pitch);

  @override
  bool operator ==(Object other) {
    if (other is MusicalScale) {
      return note == other.note && pitch == other.pitch;
    }
    return false;
  }

  @override
  int get hashCode => note.hashCode ^ pitch.hashCode;

  @override
  String toString() => '$note$pitch';
}

enum Accidental {
  natural(label: ''),
  sharp(label: '#'),
  flat(label: 'b');

  const Accidental({required this.label});

  final String label;
}

//ディグリーネームにおいて、シャープの表記は一般的でない
//またかなり適当な実装なので、後でなんとかする
//TODO シャープの実装（Noteと共通化）
enum DegreeName implements Transposable<DegreeName> {
  I(label: 'I'),
  bII(label: 'bII'),
  II(label: 'II'),
  bIII(label: 'bIII'),
  III(label: 'III'),
  IV(label: 'IV'),
  bV(label: 'bV'),
  V(label: 'V'),
  bVI(label: 'bVI'),
  VI(label: 'VI'),
  bVII(label: 'bVII'),
  VII(label: 'VII');

  const DegreeName({required this.label});

  //TODO スマートに書き換える
  factory DegreeName.parse(String label) {
    if (label == 'bIV') return III;
    if (label == '#III') return IV;
    if (label == 'bI') return VII;
    if (label == '#VII') return I;

    if (label.startsWith('#')) {
      final name = DegreeName.parse(label.substring(1));
      return values[name.index + 1];
    }
    for (final degreeName in values) {
      if (degreeName.label == label) return degreeName;
    }
    throw ArgumentError();
  }

  factory DegreeName.fromIndex(int index) {
    assert(index < 12);
    return values[index];
  }

  @override
  DegreeName transpose(int degree) =>
      DegreeName.fromIndex((index + degree) % DegreeName.values.length);

  final String label;
}

enum NaturalNote { C, D, E, F, G, A, B }

enum Note implements Transposable<Note> {
  C(naturalNote: NaturalNote.C),
  Cs(naturalNote: NaturalNote.C, accidental: Accidental.sharp),
  D(naturalNote: NaturalNote.D),
  Ds(naturalNote: NaturalNote.D, accidental: Accidental.sharp),
  E(naturalNote: NaturalNote.E),
  F(naturalNote: NaturalNote.F),
  Fs(naturalNote: NaturalNote.F, accidental: Accidental.sharp),
  G(naturalNote: NaturalNote.G),
  Gs(naturalNote: NaturalNote.G, accidental: Accidental.sharp),
  A(naturalNote: NaturalNote.A),
  As(naturalNote: NaturalNote.A, accidental: Accidental.sharp),
  B(naturalNote: NaturalNote.B);

  const Note({required this.naturalNote, this.accidental = Accidental.natural});

  factory Note.parse(String label) {
    for (final note in values) {
      if (note.label == label) return note;
    }
    throw ArgumentError();
  }

  factory Note.fromIndex(int index) {
    assert(index < 12);
    return values[index];
  }

  final NaturalNote naturalNote;
  final Accidental accidental;

  String get label => naturalNote.name + accidental.label;

  ///度数を渡すと新しいNoteを返す
  ///ex)
  ///Note.C.to(2) -> Note.D
  @override
  Note transpose(int degree) =>
      Note.fromIndex((index + degree) % Note.values.length);

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

/// 範囲は[lowest.hz, highest.hz)
Bin equalTemperamentBin(MusicalScale lowest, MusicalScale highest) {
  // 音域の参考サイト: https://tomari.org/main/java/oto.html
  // ビン幅は前の音と対象の音の中点 ~ 対象の音と次の音の中点
  // よって指定された音域分のビンを作成するには上下に１つずつ余分な音域を考える必要がある
  final hzList = List.generate(
    lowest.degreeTo(highest) + 2,
    (i) => lowest.hz * pow(MusicalScale.ratio, i - 1),
  );

  final bins = <double>[];
  for (var i = 0; i < hzList.length - 1; i++) {
    bins.add((hzList[i] + hzList[i + 1]) / 2);
  }

  return bins;
}
