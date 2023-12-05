import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load', () async {
    const loader =
        SimpleAudioLoader(path: 'assets/evals/osawa/guitar_normal_c.wav');
    final data = await loader.load();

    expect(data.buffer, isNotEmpty);
  });

  test('duration', () async {
    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(duration: 4);

    expect(data.duration.round(), 4);
  });

  test('offset', () async {
    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(duration: 4, offset: 12);

    expect(data.duration.round(), 4);
  });

  group('down sampling', () {
    test('load down sampling 44100 to 22050', () async {
      const loader =
          SimpleAudioLoader(path: 'assets/evals/osawa/guitar_normal_c.wav');
      final data = await loader.load();
      const sr = 22050;
      final duration = data.duration;

      expect(data.downSample(sr).buffer.length, sr * duration);
    });

    test('load down sampling 48000 to 22050', () async {
      const loader = SimpleAudioLoader(
          path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
      final data = await loader.load(duration: 4);
      const sr = 22050;
      final duration = data.duration;

      expect(data.downSample(sr).buffer.length, sr * duration);
    });
  });
}
