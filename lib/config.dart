import 'domains/chord.dart';
import 'domains/equal_temperament.dart';

class Config {
  //TODO あとでstatic変数は排除する
  static const sampleRate = 22050;

  static const chunkSize = 2048;
  static const chunkStride = chunkSize ~/ 2;

  // static final detectableChords = Set.unmodifiable([
  //   for (final root in Note.values)
  //     for (final type in ChordType.values.where((ct) => ct != ChordType.sus2))
  //       for (final qualities in [
  //         ChordQualities.empty,
  //         ChordQualities.seventh,
  //         ChordQualities.majorSeventh,
  //         ChordQualities(const {ChordQuality.ninth}),
  //       ])
  //         if (type.validate(qualities))
  //           Chord.fromType(type: type, root: root, qualities: qualities),
  // ]);

  //対応するコードタイプは論文を参照
  static final _qualities = [
    '',
    'm',
    'aug',
    'dim',
    'sus4',
    '7',
    'm7',
    'M7',
    'mM7',
    'aug7',
    'm7b5',
    '7sus4',
    'dim7',
    // '6',
    'm6',
    'add9',
  ];
  static final detectableChords = Set.unmodifiable([
    for (final root in Note.values)
      for (final quality in _qualities) Chord.parse(root.label + quality)
  ]);
}
