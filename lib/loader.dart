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
  const SimpleAudioLoader({this.path, this.bytes})
      : assert(path != null || bytes != null);

  final String? path;
  final Uint8List? bytes;

  @override
  Future<AudioData> load() async {
    final wav = await _read();
    final buffer = wav.toMono();
    return AudioData(buffer: buffer, sampleRate: wav.samplesPerSecond);
  }

  Future<Wav> _read() =>
      path == null ? Future.value(Wav.read(bytes!)) : Wav.readFile(path!);
}
