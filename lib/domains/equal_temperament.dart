// ignore_for_file: constant_identifier_names

import 'dart:math';

import 'package:flutter/widgets.dart';

import '../utils/histogram.dart';

typedef Notes = List<Note>;

abstract interface class Transposable<T> {
  T transpose(int degree);
}

@immutable
class MusicalScale implements Transposable<MusicalScale> {
  const MusicalScale(this.note, this.pitch);

  static const A0 = MusicalScale(Note.A, 0);
  static const C1 = MusicalScale(Note.C, 1);
  static const E2 = MusicalScale(Note.E, 2);

  static final ratio = pow(2, 1 / 12);
  static const hzOfA0 = 27.5;

  static List<double> hzList(MusicalScale lowest, MusicalScale highest) {
    final hz = lowest.toHz();
    return List.generate(
      lowest.degreeTo(highest) + 1,
      (i) => hz * pow(ratio, i),
    );
  }

  final Note note;
  final int pitch;

  ///度数を渡すと新しいMusicalScaleを返す
  @override
  MusicalScale transpose(int degree) {
    if (degree == 0) return this;

    final newNote = note.transpose(degree);
    var newPitch = pitch + degree ~/ 12;
    final noteDegreeTo = note.degreeTo(newNote);
    if (degree > 0 && noteDegreeTo.isNegative) {
      newPitch += 1;
    } else if (degree.isNegative && noteDegreeTo > 0) {
      newPitch -= 1;
    }
    return MusicalScale(newNote, newPitch);
  }

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

  ///ピッチを考慮する度数の差
  ///ex)
  ///A0 -> C1 = 3
  ///C3 -> C4 = 12
  int degreeTo(MusicalScale other) =>
      note.degreeTo(other.note) + 12 * (other.pitch - pitch);

  double toHz() => hzOfA0 * pow(ratio, MusicalScale.A0.degreeTo(this));
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
    throw ArgumentError('invalid Degree Name: $label');
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

/// Note
/// Do not use values, index. It will be nonintuitive
enum Note implements Transposable<Note> {
  Bs.sharp(NaturalNote.B, 0),
  C.natural(NaturalNote.C, 0),
  Cs.sharp(NaturalNote.C, 1),
  Db.flat(NaturalNote.D, 1),
  D.natural(NaturalNote.D, 2),
  Ds.sharp(NaturalNote.D, 3),
  Eb.flat(NaturalNote.E, 3),
  E.natural(NaturalNote.E, 4),
  Es.sharp(NaturalNote.E, 5),
  Fb.flat(NaturalNote.F, 4),
  F.natural(NaturalNote.F, 5),
  Fs.sharp(NaturalNote.F, 6),
  Gb.flat(NaturalNote.G, 6),
  G.natural(NaturalNote.G, 7),
  Gs.sharp(NaturalNote.G, 8),
  Ab.flat(NaturalNote.A, 8),
  A.natural(NaturalNote.A, 9),
  As.sharp(NaturalNote.A, 10),
  Bb.flat(NaturalNote.B, 10),
  B.natural(NaturalNote.B, 11),
  Cb.flat(NaturalNote.C, 11);

  const Note({
    required this.naturalNote,
    required this.accidental,
    required this.noteIndex,
  });

  const Note.natural(this.naturalNote, this.noteIndex)
      : accidental = Accidental.natural;

  const Note.sharp(this.naturalNote, this.noteIndex)
      : accidental = Accidental.sharp;

  const Note.flat(this.naturalNote, this.noteIndex)
      : accidental = Accidental.flat;

  factory Note.parse(String label) {
    for (final note in values) {
      if (note.toString() == label) return note;
    }
    throw ArgumentError();
  }

  final NaturalNote naturalNote;
  final Accidental accidental;
  final int noteIndex;

  static Notes sharpNotes = const [C, Cs, D, Ds, E, F, Fs, G, Gs, A, As, B];

  static Notes flatNotes = const [C, Db, D, Eb, E, F, Gb, G, Ab, A, Bb, B];

  static int length = 12;

  @override
  String toString() => naturalNote.name + accidental.label;

  ///度数を渡すと新しいNoteを返す
  ///ex)
  ///Note.C.to(2) -> Note.D
  @override
  Note transpose(int degree) => Note.sharpNotes[(noteIndex + degree) % length];

  ///度数の差。一般にCが基準であるため、それに準拠
  ///1オクターブで見た時の差とし、音高が高い方が正とする
  ///ex)
  ///D -> A = 7
  ///D -> C = -2
  int degreeTo(Note other) => other.noteIndex - noteIndex;

  Note toSharp() => switch (accidental) {
        Accidental.natural || Accidental.sharp => this,
        Accidental.flat => sharpNotes[noteIndex],
      };

  Note toFlat() => switch (accidental) {
        Accidental.natural || Accidental.flat => this,
        Accidental.sharp => flatNotes[noteIndex],
      };

  ///負の場合、+12するdegreeTo
  int positiveDegreeTo(Note other) {
    final degree = degreeTo(other);
    return degree.isNegative ? length + degree : degree;
  }
}

enum Degree {
  P1,
  m2,
  M2,
  m3,
  M3,
  P4,
  d5,
  P5,
  M6,
  m7,
  M7;
}

/// 範囲は lowest.hz <= x <= highest.hz
/// highestを含む
Bin equalTemperamentBin(MusicalScale lowest, MusicalScale highest) {
  // 音域の参考サイト: https://tomari.org/main/java/oto.html
  // ビン幅は前の音と対象の音の中点 ~ 対象の音と次の音の中点
  // よって指定された音域分のビンを作成するには上下に１つずつ余分な音域を考える必要がある
  final hzList =
      MusicalScale.hzList(lowest.transpose(-1), highest.transpose(1));

  final bins = <double>[];
  for (var i = 0; i < hzList.length - 1; i++) {
    bins.add((hzList[i] + hzList[i + 1]) / 2);
  }

  return bins;
}
