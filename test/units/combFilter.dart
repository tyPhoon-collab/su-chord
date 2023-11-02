import 'package:chord/domains/chroma_calculators/comb_filter.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  late final AudioData sampleData;
  late final AudioData noteC3Data;
  late final AudioData chordCData;

  setUpAll(() async {
    sampleData = await AudioLoader.sample.load(sampleRate: 22050);
    noteC3Data =
        await const SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav')
            .load(sampleRate: 22050);
    chordCData =
        await const SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav')
            .load(sampleRate: 22050);
  });
  test('one note', () async {
    final chroma = CombFilterChromaCalculator(
            magnitudesCalculable: MagnitudesCalculator())(noteC3Data)
        .first;

    debugPrint(chroma.toString());
    expect(chroma.maxIndex, 0);
  });

  test('chord', () async {
    final chroma = CombFilterChromaCalculator(
            magnitudesCalculable: MagnitudesCalculator())(chordCData)
        .first;

    expect(chroma, isNotNull);
  });

  test('std dev coef', () async {
    final f = factory8192_0;
    final data = sampleData.cut(duration: 4);

    const contexts = [
      CombFilterContext(hzStdDevCoefficient: 1 / 24),
      CombFilterContext(hzStdDevCoefficient: 1 / 48),
// ignore: avoid_redundant_argument_values
      CombFilterContext(hzStdDevCoefficient: 1 / 72),
      CombFilterContext(hzStdDevCoefficient: 1 / 96),
    ];

    for (final c in contexts) {
      final chroma = f.filter
          .interval(4.seconds)(
            CombFilterChromaCalculator(
              magnitudesCalculable: f.magnitude.stft(),
              context: c,
            ).call(data),
          )
          .first
          .normalized;

      debugPrint(chroma.toString());
    }
  });

  test('log vs normal', () async {
    final data = sampleData.cut(duration: 4);

    final filter = factory8192_0.filter.interval(4.seconds);

    debugPrint(filter(
      factory8192_0.bigRange.combFilter().call(data),
    ).first.normalized.toString());

    debugPrint(filter(
      factory8192_0.bigRange
          .combFilter(
              magnitudesCalculable: factory8192_0.magnitude.stft(
            scalar: MagnitudeScalar.ln,
          ))
          .call(data),
    ).first.normalized.toString());
  });

  test('guitar tuning', () async {
    final ccd = factory8192_0.filter.interval(3.seconds);
    final chromas = ccd(factory8192_0.guitarRange
        .combFilter()
        .call(sampleData.cut(duration: 4)));

    expect(chromas[0], isNotNull);
  });
}
