import 'dart:typed_data';

import 'package:chord/loader.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stft', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load();

    const chunkSize = 2048;
    final stft = STFT(chunkSize, Window.hanning(chunkSize));

    final spectrogram = <Float64List>[];
    stft.run(data.buffer, (freq) {
      spectrogram.add(freq.discardConjugates().magnitudes());
    });

    expect(spectrogram, isNotEmpty);
  });

  // 音階ごとの周波数
  // https://tomari.org/main/java/oto.html
  test('stft one note', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav');
    final data = await loader.load();

    const chunkSize = 2048;
    final stft = STFT(chunkSize, Window.hanning(chunkSize));

    final spectrogram = <Float64List>[];
    stft.run(data.buffer, (freq) {
      spectrogram.add(freq.discardConjugates().magnitudes());
    });

    final freqResolution = data.sampleRate / chunkSize;

    // 27	123.471	シ2	B2
    // 28	130.813	ド3	C3
    // 29	138.591	ド#3	C#3

    final maxIndex = _maxIndex(spectrogram[10]);

    expect(maxIndex, (130.813 / freqResolution).round());
  });
}

// 配列のmaxIndexを出す関数
int _maxIndex(List<num> array) {
  // 最大値とそのインデックスを初期化
  num max = array[0];
  int index = 0;
  // 配列の要素をループして最大値とそのインデックスを更新
  for (int i = 1; i < array.length; i++) {
    if (array[i] > max) {
      max = array[i];
      index = i;
    }
  }
  // 最大値のインデックスを返す
  return index;
}
