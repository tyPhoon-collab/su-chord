import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:wav/wav.dart';

@immutable
class AudioData {
  const AudioData({required this.buffer, required this.sampleRate});

  final Float64List buffer;
  final int sampleRate;

  double get duration => buffer.length / sampleRate;

  //TODO add offset pram
  AudioData cut(double? duration) {
    if (duration == null) return this;
    final newBuffer = buffer.sublist(0, (duration * sampleRate).toInt());
    return AudioData(buffer: newBuffer, sampleRate: sampleRate);
  }

  AudioData downSample(int? newSampleRate) {
    if (newSampleRate == null) return this;

    final newData = <double>[];
    final sampleRateRatio = sampleRate / newSampleRate;
    double interval = sampleRateRatio;

    for (int i = 0; i < buffer.length;) {
      final factor = interval.floor();

      double average = 0.0;
      for (int j = 0; j < factor; j++) {
        if (i + j < buffer.length) {
          average += buffer[i + j];
        }
      }
      average /= factor;
      newData.add(average);
      interval += sampleRateRatio - factor;
      i += factor;
    }

    return AudioData(
      buffer: Float64List.fromList(newData),
      sampleRate: newSampleRate,
    );
  }
}

abstract interface class AudioLoader {
  Future<AudioData> load({double? duration, int? sampleRate});
}

final class SimpleAudioLoader implements AudioLoader {
  const SimpleAudioLoader({this.path, this.bytes})
      : assert(path != null || bytes != null);

  final String? path;
  final Uint8List? bytes;

  @override
  Future<AudioData> load({double? duration, int? sampleRate}) async {
    final wav = await _read();
    final sr = wav.samplesPerSecond;
    final buffer = wav.toMono();
    return AudioData(buffer: buffer, sampleRate: sr)
        .cut(duration)
        .downSample(sampleRate);
  }

  Future<Wav> _read() =>
      path == null ? Future.value(Wav.read(bytes!)) : Wav.readFile(path!);
}
