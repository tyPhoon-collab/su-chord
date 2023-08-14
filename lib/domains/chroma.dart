import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:flutter/widgets.dart';

import '../loader.dart';

//クロマ同士の計算などの利便化のために、クラス化する
@immutable
final class Chroma {
  const Chroma(this.values);

  final List<double> values;
}

abstract interface class ChromaCalculable {
  Chroma calc(AudioData audioData);
}

class Point {
  Point({required this.x, required this.y, required this.weight});

  final double x;
  final double y;
  final double weight;
}

/// a / b in complex
Float64x2 _div(Float64x2 a, Float64x2 b) {
  final c = b.x * b.x + b.y * b.y;
  return Float64x2((a.x * b.x + a.y * b.y) / c, (a.y * b.x - a.x * b.y) / c);
}

class ReassignmentChromaCalculator implements ChromaCalculable {
  ReassignmentChromaCalculator({this.chunkSize = 2048}) {
    final window = Window.hanning(chunkSize);

    final windowD = Float64List.fromList(window
        .mapIndexed((i, data) => data - (i > 0 ? window[i - 1] : 0.0))
        .toList());
    final windowT = Float64List.fromList(
        window.mapIndexed((i, data) => data * (i - chunkSize / 2)).toList());

    stft = STFT(chunkSize, window);
    stftD = STFT(chunkSize, windowD);
    stftT = STFT(chunkSize, windowT);
  }

  final int chunkSize;
  late final STFT stft;
  late final STFT stftD;
  late final STFT stftT;
  var magnitudes = <Float64List>[];

  @override
  Chroma calc(AudioData audioData) {
    // TODO: implement calc
    throw UnimplementedError();
  }

  List<Point> tmp(AudioData data) {
    final s = <Float64x2List>[];

    stft.run(data.buffer, (freq) {
      final f = freq.discardConjugates();
      s.add(f);
      magnitudes.add(f.magnitudes());
    });

    final sD = <Float64x2List>[];
    stftD.run(data.buffer, (freq) {
      sD.add(freq.discardConjugates());
    });

    final sT = <Float64x2List>[];
    stftT.run(data.buffer, (freq) {
      sT.add(freq.discardConjugates());
    });

    final points = <Point>[];
    final dt = chunkSize / data.sampleRate;
    final df = data.sampleRate / chunkSize;

    for (int i = 0; i < s.length; ++i) {
      for (int j = 0; j < s[i].length; ++j) {
        points.add(
          Point(
            x: i * dt + _div(sT[i][j], s[i][j]).x / data.sampleRate,
            y: j * df -
                _div(sD[i][j], s[i][j]).y * (0.5 * data.sampleRate / pi),
            weight: magnitudes[i][j],
          ),
        );
      }
    }

    return points;
  }
}
