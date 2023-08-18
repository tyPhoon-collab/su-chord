import 'domains/chord.dart';
import 'domains/equal_temperament.dart';

class Config {
  //TODO あとでstatic変数は排除する
  static const sampleRate = 22050;

  static const chunkSize = 2048;
  static const chunkStride = chunkSize ~/ 4;

  static final defaultTemplateChords = [
    for (final root in Note.values)
      for (final type in ChordType.values.where((ct) => ct != ChordType.sus2))
        for (final qualities in [
          ChordQualities.empty,
          ChordQualities(const {ChordQuality.seventh}),
          ChordQualities(const {ChordQuality.majorSeventh}),
          ChordQualities(const {ChordQuality.ninth}),
        ])
          if (type.validate(qualities))
            Chord.fromType(type: type, root: root, qualities: qualities)
  ];
}
