import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:wav/wav.dart';

@immutable
class AudioData {
  const AudioData({required this.buffer, required this.sampleRate});

  final Float64List buffer;
  final int sampleRate;

  double get duration => buffer.length / sampleRate;
}

abstract interface class AudioLoader {
  Future<AudioData> load();
}

final class SimpleAudioLoader implements AudioLoader {
  const SimpleAudioLoader({required this.path});

  final String path;

  @override
  Future<AudioData> load() async {
    final wav = await Wav.readFile(path);
    final buffer = wav.toMono();
    return AudioData(buffer: buffer, sampleRate: wav.samplesPerSecond);
  }
}
