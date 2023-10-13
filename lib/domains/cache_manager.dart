import 'package:flutter/foundation.dart';

import 'chroma.dart';

mixin MagnitudesCacheManager {
  @protected
  final Magnitudes cachedMagnitudes = [];

  void updateCacheMagnitudes(Magnitudes magnitudes, bool flush) {
    if (flush) {
      cachedMagnitudes.clear();
    } else {
      cachedMagnitudes.addAll(magnitudes);
    }
  }
}

mixin SampleRateCacheManager {
  int? _cachedSampleRate;

  int? get cachedSampleRate => _cachedSampleRate;

  void updateCacheSampleRate(int sampleRate) {
    if (sampleRate != _cachedSampleRate) {
      _cachedSampleRate = sampleRate;
      onSampleRateChanged(sampleRate);
    }
  }

  void onSampleRateChanged(int newSampleRate) {}
}
