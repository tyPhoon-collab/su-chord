import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'writer.dart';

void main() {
  late final AudioData data;
  // late final AudioData noteC3Data;
  // late final AudioData chordCData;

  setUpAll(() async {
    data = await AudioLoader.sample.load(sampleRate: 22050);
    // noteC3Data =
    //     await const SimpleAudioLoader(path: 'assets/evals/guitar_note_c3.wav')
    //         .load(sampleRate: 22050);
    // chordCData =
    //     await const SimpleAudioLoader(path: 'assets/evals/guitar_normal_c.wav')
    //         .load(sampleRate: 22050);
  });

  group('pcp bar chart', () {
    const writer = PCPChartWriter();
    final f = factory8192_0;

    group('power point example', () {
      test('PCP of G', () async {
        final chromas = f.guitarRange.reassignCombFilter(data.cut(duration: 4));

        final pcp = f.filter.interval(4.seconds).call(chromas).first;
        await writer(pcp.normalized, title: 'PCP of G');
      });

      test('template of G', () async {
        await writer(
          PCP(const [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1]).normalized,
          title: 'Template of G',
        );
      });

      test('PCP of C', () async {
        final chromas = f.guitarRange.reassignCombFilter(data.cut(
          duration: 4,
          offset: 12,
        ));

        final pcp = f.filter.interval(4.seconds).call(chromas).first;
        await writer(pcp.normalized, title: 'PCP of C');
      });

      test('template of C', () async {
        await writer(
          PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]).normalized,
          title: 'Template of C',
        );
      });
    });

    group('scalar', () {
      test('third scaled template of C', () async {
        await writer(
          const ThirdHarmonicChromaScalar(0.2)
              .call(PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]))
              .normalized,
          title: 'third scaled template of C',
        );
      });

      test('harmonics scaled template of C', () async {
        await writer(
          HarmonicsChromaScalar()
              .call(PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]))
              .normalized,
          title: 'harmonics scaled template of C',
        );
      });
    });
  });

  group('spec', () {
    final f = factory2048_1024;
    final writer = SpecChartWriter(
      sampleRate: f.context.sampleRate,
      chunkSize: f.context.chunkSize,
      chunkStride: f.context.chunkStride,
    );

    test('1 compare stft vs reassignment', () async {
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

    test('2 compare stft vs reassignment', () async {
      final data = await AudioLoader.sample.load(
        duration: 16,
        sampleRate: f.context.sampleRate,
      );

      final mags1 = f.magnitude.stft().call(data);
      final mags2 =
          f.magnitude.reassignment(overrideChunkSize: 8192).call(data);

      await Future.wait([
        writer(mags1, title: 'mags ${f.context}'),
        writer(mags2, title: 'reassignment ${f.context}'),
      ]);
    });
  });

  group('chromagram', () {
    final f = factory8192_0;
    final writer = SpecChartWriter.chroma(
      sampleRate: f.context.sampleRate,
      chunkSize: f.context.chunkSize,
      chunkStride: f.context.chunkStride,
    );

    test('_compare', () async {
      final cutData = data.cut(duration: 16);
      final estimators = [
        f.guitarRange.combFilter,
        f.guitarRange.reassignCombFilter,
        f.guitarRange.reassignment,
      ];

      await Future.wait([
        for (final e in estimators)
          writer(e.call(cutData), title: 'chromagram $e ${f.context}'),
      ]);
    });

    test('common', () async {
      final chromas = f.guitarRange.reassignCombFilter(data.cut(duration: 16));
      await writer(chromas, title: 'chromagram');
    });

    test('log scaled', () async {
      final chromas = f.guitarRange
          .combFilterWith(
            magnitudesCalculable:
                f.magnitude.reassignment(scalar: MagnitudeScalar.ln),
          )
          .call(data.cut(duration: 12));
      await writer(chromas, title: 'chromagram');
    });

    test('filter', () async {
      final filters = [
        const ThresholdFilter(threshold: 20),
        // GaussianFilter.dt(stdDev: 0.2, dt: f.context.dt),
      ];
      var chromas = f.guitarRange.reassignCombFilter(data.cut(duration: 12));
      await writer(chromas, title: 'chromagram 0');

      int count = 0;
      for (final filter in filters) {
        count++;
        chromas = filter(chromas);
        await writer(chromas, title: 'chromagram $count $filter');
      }
    });
  });
}
