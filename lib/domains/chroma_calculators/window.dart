import 'dart:math';
import 'dart:typed_data';

import 'package:fftea/stft.dart';

enum NamedWindowFunction {
  hanning,
  hamming,
  blackman,
  blackmanHarris,
  bartlett;

  Float64List toWindow(int chunkSize) => switch (this) {
        NamedWindowFunction.hanning => Window.hanning(chunkSize),
        NamedWindowFunction.hamming => Window.hamming(chunkSize),
        NamedWindowFunction.blackman => Window.blackman(chunkSize),
        NamedWindowFunction.bartlett => Window.bartlett(chunkSize),
        NamedWindowFunction.blackmanHarris =>
          WindowExtension.blackmanHarris(chunkSize),
      };

  Float64List toDerivativeWindow(int chunkSize) => switch (this) {
        NamedWindowFunction.hanning =>
          WindowExtension.derivativeHanning(chunkSize),
        NamedWindowFunction.hamming =>
          WindowExtension.derivativeHamming(chunkSize),
        NamedWindowFunction.blackman =>
          WindowExtension.derivativeBlackman(chunkSize),
        NamedWindowFunction.blackmanHarris =>
          WindowExtension.derivativeBlackmanHarris(chunkSize),
        _ => WindowExtension.gradient(toWindow(chunkSize)),
      };
}

extension WindowExtension on Float64List {
  //https://jp.mathworks.com/help/signal/ref/blackmanharris.html
  static Float64List blackmanHarris(int size) => _makeWindow(
        size,
        (i) =>
            0.35875 -
            _cosineClosure(size, 0.48829).call(i) +
            _cosineClosure(size, 0.14128, 4).call(i) -
            _cosineClosure(size, 0.01168, 6).call(i),
      );

  static Float64List derivativeHanning(int size) =>
      _makeWindow(size, _derivativeSineClosure(size, 0.5));

  static Float64List derivativeHamming(int size) =>
      _makeWindow(size, _derivativeSineClosure(size, 0.46));

  static Float64List derivativeBlackman(int size) => _makeWindow(
        size,
        (i) =>
            _derivativeSineClosure(size, 0.5).call(i) -
            _derivativeSineClosure(size, 0.08, 4).call(i),
      );

  static Float64List derivativeBlackmanHarris(int size) => _makeWindow(
        size,
        (i) =>
            _derivativeSineClosure(size, 0.48829).call(i) -
            _derivativeSineClosure(size, 0.14128, 4).call(i) +
            _derivativeSineClosure(size, 0.01168, 6).call(i),
      );

  ///両端は前進差分と後退差分、ほかは中心差分を採用する微分関数
  static Float64List gradient(Float64List window) {
    final len = window.length;
    final windowD = Float64List(len);

    windowD[0] = window[1] - window.first;
    for (int i = 1; i < window.length - 1; i++) {
      windowD[i] = (window[i + 1] - window[i - 1]) / 2;
    }
    windowD[len - 1] = window.last - window[len - 2];

    return windowD;
  }

  static Float64List _makeWindow(int size, double Function(int i) closure) {
    final window = Float64List(size);

    for (int i = 0; i < window.length; i++) {
      window[i] = closure(i);
    }

    return window;
  }

  static double Function(int i) _derivativeSineClosure(
    int size,
    double amplitude, [
    double scaleCoefficient = 2,
  ]) {
    final scale = scaleCoefficient * pi / (size - 1);

    return (i) => amplitude * scale * sin(scale * i);
  }

  static double Function(int i) _cosineClosure(
    int size,
    double amplitude, [
    double scaleCoefficient = 2,
  ]) {
    final scale = scaleCoefficient * pi / (size - 1);

    return (i) => amplitude * cos(scale * i);
  }
}
