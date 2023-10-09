import 'package:flutter/foundation.dart';
import 'package:wav/wav.dart';

@immutable
class AudioData {
  const AudioData({required this.buffer, required this.sampleRate});

  AudioData.empty({this.sampleRate = 22050}) : buffer = Float64List(0);

  final Float64List buffer;
  final int sampleRate;

  double get duration => buffer.length / sampleRate;

  //TODO expand if duration > this.duration
  AudioData cut({
    double? duration,
    double offset = 0,
  }) {
    if (duration == null || duration >= this.duration) return this;
    final newBuffer = buffer.sublist(
        (offset * sampleRate).toInt(), (duration * sampleRate).toInt());
    return AudioData(buffer: newBuffer, sampleRate: sampleRate);
  }

  AudioData cutByIndex([
    int startIndex = 0,
    int? endIndex,
  ]) {
    if (startIndex < 0) {
      startIndex = 0;
    }

    if (endIndex != null && buffer.length <= endIndex) {
      endIndex = buffer.length - 1;
    }
    final newBuffer = buffer.sublist(startIndex, endIndex);
    return AudioData(buffer: newBuffer, sampleRate: sampleRate);
  }

  AudioData downSample(int? newSampleRate) {
    if (newSampleRate == null || newSampleRate >= sampleRate) return this;

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

  static const sample =
      SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');

  static const sample2 = SimpleAudioLoader(
      path:
          'assets/evals/Halion_CleanStratGuitar/1_Halion_CleanStratGuitar.wav');
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
        .cut(duration: duration)
        .downSample(sampleRate);
  }

  Future<Wav> _read() =>
      path == null ? Future.value(Wav.read(bytes!)) : Wav.readFile(path!);
}

//デルタ関数をロードする関数
final class DeltaFunctionAudioLoader implements AudioLoader {
  @override
  Future<AudioData> load({double? duration, int? sampleRate}) {
    sampleRate ??= 22050;
    final buffer = List.filled(sampleRate * 2, 0.0);
    buffer[sampleRate ~/ 2] = 1;
    return Future.value(AudioData(
      buffer: Float64List.fromList(buffer),
      sampleRate: sampleRate,
    ));
  }
}
