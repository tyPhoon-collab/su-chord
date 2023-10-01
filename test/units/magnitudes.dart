import 'package:chord/config.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../writer.dart';

void main() {
  late final AudioData data;
  late final Writer writer;

  setUpAll(() async {
    data = await AudioLoader.sample.load(
      duration: 4,
      sampleRate: Config.sampleRate,
    );
    writer = ChromaChartWriter(sampleRate: data.sampleRate);
  });

  test('magnitudes', () async {
    final c = factory2048_1024.magnitude.stft();
    final mags = c(data);
    expect(mags, isNotEmpty);
    await writer(mags, title: 'mags');
  });

  test('reassignment', () async {
    final c = factory2048_1024.magnitude.reassignment();
    final mags = c(data);
    expect(mags, isNotEmpty);
    await writer(mags, title: 'mags reassignment');
  });

  test('same size', () {
    for (final f in [factory8192_0, factory2048_1024]) {
      final m1 = f.magnitude.stft().call(data);
      final m2 = f.magnitude.reassignment().call(data);

      expect(m1.length, m2.length);
      expect(m1.first.length, m2.first.length);
    }
  });
}
