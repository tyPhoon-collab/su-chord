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
  Future<AudioData> load({double? duration});
}

final class SimpleAudioLoader implements AudioLoader {
  const SimpleAudioLoader({this.path, this.bytes})
      : assert(path != null || bytes != null);

  final String? path;
  final Uint8List? bytes;

  @override
  Future<AudioData> load({double? duration}) async {
    final wav = await _read();

    final sr = wav.samplesPerSecond;

    var buffer = wav.toMono();
    if (duration != null) {
      buffer = buffer.sublist(0, (duration * sr).toInt());
    }
    return AudioData(buffer: buffer, sampleRate: sr);
  }

  Future<Wav> _read() =>
      path == null ? Future.value(Wav.read(bytes!)) : Wav.readFile(path!);
}
