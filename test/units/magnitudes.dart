import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late final AudioData data;
  setUpAll(() async {
    data = await AudioLoader.sample.load(duration: 4);
  });

  test('magnitudes', () {
    final c = factory2048_1024.magnitude.stft();
    final mags = c(data);
    expect(mags, isNotEmpty);
  });

  test('reassignment', () {
    final c = factory2048_1024.magnitude.reassignment();
    final mags = c(data);
    expect(mags, isNotEmpty);
  });

  test('same size', () {
    for (final f in [factory8192_0, factory2048_1024]) {
      final m1 = f.magnitude.stft()(data);
      final m2 = f.magnitude.reassignment()(data);

      expect(m1.length, m2.length);
      expect(m1.first.length, m2.first.length);
    }
  });
}
