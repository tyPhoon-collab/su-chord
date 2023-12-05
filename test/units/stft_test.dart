import 'dart:typed_data';

import 'package:chord/utils/loaders/audio.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../util.dart';

void main() {
  test('stft', () async {
    final data = await DataSet().osawa.C;

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
    final data = await DataSet().osawa.C3;

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
    final data = await DataSet().osawa.C;

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
    final data = await AudioLoader.sample.load(duration: 2);

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
