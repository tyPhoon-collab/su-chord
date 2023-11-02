import 'dart:math';

import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'writer.dart';

void main() {
  late final AudioData data;
  late final AudioData data_G; // ignore: non_constant_identifier_names
  late final AudioData data_C; // ignore: non_constant_identifier_names
  late final AudioData data_G_Em_Bm_C; // ignore: non_constant_identifier_names
  late final AudioData nutcrackerData;

  setUpAll(() async {
    data = await AudioLoader.sample.load(sampleRate: 22050);
    data_G = data.cut(duration: 4.1);
    data_C = data.cut(duration: 4, offset: 12.1);
    data_G_Em_Bm_C = data.cut(duration: 16.1);

    nutcrackerData = await const SimpleAudioLoader(
      path: 'assets/evals/nutcracker.wav',
    ).load(
      duration: 30,
      sampleRate: 22050,
    );
  });

  group('pcp bar chart', () {
    const writer = PCPChartWriter();

    test('compare by change window size', () async {
      final factories = [
        factory8192_0,
        factory2048_0,
        factory2048_1024,
      ];

      await Future.wait([
        for (final f in factories)
          for (final cc in [
            f.guitarRange.combFilter(),
            f.guitarRange.reassignCombFilter(),
          ])
            writer(
              f.filter.interval(4.seconds).call(cc(data_G)).first.normalized,
              title: 'pcp of G, ${f.context} $cc',
            )
      ]);
    });

    test('compare', () async {
      final factories = [factory8192_0, factory4096_0];
      final data = await const SimpleAudioLoader(
              path:
                  'assets/evals/Halion_CleanGuitarVX/13_1119_Halion_CleanGuitarVX.wav')
          .load(sampleRate: 22050, duration: 4.1, offset: 12);

      await Future.wait([
        for (final f in factories)
          for (final cc in [
            f.guitarRange.reassignCombFilter(),
            f.guitarRange.reassignCombFilter(scalar: MagnitudeScalar.ln),
          ])
            writer(
              f.filter.interval(4.seconds).call(cc.call(data)).first.normalized,
              title: 'pcp of G $cc ${f.context}',
            )
      ]);
    });

    group('power point example', () {
      final f = factory8192_0;

      test('PCP of G', () async {
        final chromas = f.guitarRange.reassignCombFilter().call(data_G);

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
        final chromas = f.guitarRange.reassignCombFilter().call(data_C);

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

    test('stft vs reassignment', () async {
      const scalar = MagnitudeScalar.dB;

      final mags1 = f.magnitude.stft(scalar: scalar).call(nutcrackerData);
      final mags2 =
          f.magnitude.reassignment(scalar: scalar).call(nutcrackerData);

      await Future.wait([
        writer(mags1, title: '${scalar.name} mags ${f.context}'),
        writer(mags2, title: '${scalar.name} reassignment ${f.context}'),
      ]);
    });

    test('stft vs reassignment', () async {
      final mags1 = f.magnitude.stft().call(data);
      final mags2 = f.magnitude
          .reassignment(overrideChunkSize: 8192)
          .call(data.cut(duration: 16));

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

    test('compare', () async {
      final estimators = [
        f.guitarRange.combFilter(),
        f.guitarRange.reassignCombFilter(),
        f.guitarRange.reassignment(),
      ];

      await Future.wait(
        estimators.map((e) => writer(
              e.call(data_G_Em_Bm_C),
              title: 'chromagram $e ${f.context}',
            )),
      );
    });

    test('common', () async {
      final chromas = f.guitarRange.reassignCombFilter().call(data_G_Em_Bm_C);
      await writer(chromas, title: 'chromagram');
    });

    test('log scaled', () async {
      final chromas = f.guitarRange
          .reassignCombFilter(scalar: MagnitudeScalar.ln)
          .call(data.cut(duration: 12));
      await writer(chromas, title: 'chromagram');
    });

    group('filter', () {
      test('threshold 20', () async {
        final filters = [
          const ThresholdFilter(threshold: 20),
          // GaussianFilter.dt(stdDev: 0.2, dt: f.context.dt),
        ];
        final cc = f.guitarRange.reassignCombFilter();
        var chromas = cc(data.cut(duration: 12));
        await writer(chromas, title: 'chromagram 0 $cc');

        int count = 0;
        for (final filter in filters) {
          count++;
          chromas = filter(chromas);
          await writer(chromas, title: 'chromagram $count $filter $cc');
        }
      });

      test('threshold log', () async {
        final filters = [
          ThresholdFilter(threshold: log(20)),
          // GaussianFilter.dt(stdDev: 0.2, dt: f.context.dt),
        ];
        final cc = f.guitarRange.reassignCombFilter(scalar: MagnitudeScalar.ln);
        var chromas = cc(data.cut(duration: 12));
        await writer(chromas, title: 'chromagram 0 $cc');

        int count = 0;
        for (final filter in filters) {
          count++;
          chromas = filter(chromas);
          await writer(chromas, title: 'chromagram $count $filter $cc');
        }
      });
    });
  });
}
