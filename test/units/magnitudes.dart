import 'package:chord/domains/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late final AudioData data;
  late final EstimatorFactory factory;

  setUpAll(() async {
    data = await AudioLoader.sample.load(
      duration: 4,
      sampleRate: 22050,
    );
    factory = factory8192_0;
  });

  test('stft', () async {
    final c = factory.magnitude.stft();
    final mags = c(data);
    expect(mags, isNotEmpty);
  });

  test('reassignment', () async {
    final c = factory.magnitude.reassignment();
    final mags = c(data);
    expect(mags, isNotEmpty);
  });

  // test('same size for different chunkSize and chunkStride', () {
  //   for (final f in [factory8192_0, factory2048_1024]) {
  //     final m1 = f.magnitude.stft().call(data);
  //     final m2 = f.magnitude.reassignment().call(data);
  //
  //     expect(m1.length, m2.length);
  //     expect(m1.first.length, m2.first.length);
  //   }
  // });
}
