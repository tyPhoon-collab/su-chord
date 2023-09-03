import 'dart:typed_data';

import 'package:chord/config.dart';
import 'package:chord/utils/loader.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util.dart';

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

    final maxIndex = _findMaxIndex(spectrogram[10]);

    expect(maxIndex, (130.813 / freqResolution).round());
  });

  test('stft comb filter', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load(sampleRate: Config.sampleRate);

    const chunkSize = 2048;
    final stft = STFT(chunkSize, Window.hanning(chunkSize));

    final spectrogram = <Float64List>[];
    stft.run(data.buffer, (freq) {
      spectrogram.add(freq.discardConjugates().magnitudes());
    });

    expect(spectrogram, isNotEmpty);
  });

  test('stft stream', () async {
    const chunkSize = 10000;
    final stft = STFT(chunkSize, Window.hanning(chunkSize));
    final data = await AudioLoader.sample.load();

    void callback(Float64x2List freq) {
      debugPrint(freq.length.toString());
    }

    await for (final data in const AudioStreamEmulator().stream(data)) {
      stft.stream(data.buffer, callback);
    }
    stft.flush(callback);
  });
}

int _findMaxIndex(List<num> array) {
  if (array.isEmpty) {
    throw ArgumentError('Array cannot be empty');
  }

  num max = array[0];
  int maxIndex = 0;

  for (int i = 1; i < array.length; i++) {
    if (array[i] > max) {
      max = array[i];
      maxIndex = i;
    }
  }

  return maxIndex;
}
