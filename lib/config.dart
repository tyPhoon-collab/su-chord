import 'domains/chord.dart';
import 'domains/equal_temperament.dart';

class Config {
  //TODO あとでstatic変数は排除する
  static const sampleRate = 22050;

  static const chunkSize = 2048;

  static final defaultTemplateChords = [
    for (final root in Note.values) ...[
      Chord.major(root: root),
      Chord.minor(root: root),
    ]
  ];
}
