import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load down sampling 44100 to 22050', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load();
    const sr = 22050;
    final duration = data.duration;

    expect(data.downSample(sr).buffer.length, sr * duration);
  });

  test('load down sampling 48000 to 22050', () async {
    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(duration: 4);
    const sr = 22050;
    final duration = data.duration;

    expect(data.downSample(sr).buffer.length, sr * duration);
  });
}
