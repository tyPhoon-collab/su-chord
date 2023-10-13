import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'writer.dart';

void main() {
  late final AudioData sampleData;
  // late final AudioData noteC3Data;
  // late final AudioData chordCData;

  setUpAll(() async {
    sampleData = await AudioLoader.sample.load(sampleRate: 22050);
    // noteC3Data =
    //     await const SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav')
    //         .load(sampleRate: 22050);
    // chordCData =
    //     await const SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav')
    //         .load(sampleRate: 22050);
  });

  group('pcp', () {
    final writer = PCPChartWriter();
    final f = factory8192_0;
    test('PCP of G', () async {
      final chromas =
          f.guitarRange.reassignCombFilter(sampleData.cut(duration: 4));

      final pcp = f.filter.interval(4.seconds).call(chromas).first;
      await writer(pcp.normalized, title: 'PCP of G');
    });

    test('template of G', () async {
      await writer(
        PCP(const [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1]).normalized,
        title: 'Template of G',
      );
    });
  });

  group('spec', () {
    final f = factory2048_1024;
    final writer = SpecChartWriter(
      sampleRate: f.context.sampleRate,
      chunkSize: f.context.chunkSize,
      chunkStride: f.context.chunkStride,
    );

    test('compare stft vs reassignment', () async {
      final data =
          await const SimpleAudioLoader(path: 'assets/evals/nutctracker.wav')
              .load(duration: 30, sampleRate: f.context.sampleRate);

      const scalar = MagnitudeScalar.dB;

      final mags1 = f.magnitude.stft(scalar: scalar).call(data);
      final mags2 = f.magnitude.reassignment(scalar: scalar).call(data);

      await Future.wait([
        writer(mags1, title: '${scalar.name} mags ${f.context}'),
        writer(mags2, title: '${scalar.name} reassignment ${f.context}'),
      ]);
    });
  });
}
