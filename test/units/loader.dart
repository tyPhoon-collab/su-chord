import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('load', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load();

    expect(data.buffer, isNotEmpty);
  });

  test('load duration', () async {
    const loader =
        SimpleAudioLoader(path: 'assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final data = await loader.load(duration: 4);

    expect(data.duration.round(), 4);
  });
}
