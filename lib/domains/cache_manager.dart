

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
