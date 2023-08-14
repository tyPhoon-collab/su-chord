import 'package:chord/utils/loader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('loader.load', () async {
    const loader = SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav');
    final data = await loader.load();

    expect(data.buffer, isNotEmpty);
  });
}
