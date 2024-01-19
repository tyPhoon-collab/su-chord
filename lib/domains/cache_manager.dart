import 'package:flutter/foundation.dart';

///サンプルレートをキャッシュし、サンプルレートが変更されたときのコールバックを管理する
///基本的にパフォーマンス向上のために使われる
mixin SampleRateCacheManager {
  int? _cachedSampleRate;

  @protected
  int? get cachedSampleRate => _cachedSampleRate;

  void updateCacheSampleRate(int sampleRate) {
    if (sampleRate != _cachedSampleRate) {
      onSampleRateChanged(sampleRate);
    }
  }

  @mustCallSuper
  // ignore: use_setters_to_change_properties
  void onSampleRateChanged(int newSampleRate) {
    _cachedSampleRate = newSampleRate;
  }
}
