import 'dart:math';

import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/factory.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

import 'data_set.dart';
import 'writer.dart';

void main() {
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
            f.guitar.combFilter(),
            f.guitar.reassignCombFilter(),
          ])
            writer(
              f.filter
                  .interval(4.seconds)
                  .call(cc(await DataSet().G))
                  .first
                  .l2normalized,
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
            f.guitar.reassignCombFilter(),
            f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
          ])
            writer(
              f.filter
                  .interval(4.seconds)
                  .call(cc.call(data))
                  .first
                  .l2normalized,
              title: 'pcp of G $cc ${f.context}',
            )
      ]);
    });

    group('power point example', () {
      final f = factory8192_0;

      test('PCP of G', () async {
        final chromas = f.guitar.reassignCombFilter().call(await DataSet().G);

        final pcp = f.filter.interval(4.seconds).call(chromas).first;
        await writer(pcp.l2normalized, title: 'PCP of G');
      });

      test('template of G', () async {
        await writer(
          PCP(const [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 1]).l2normalized,
          title: 'Template of G',
        );
      });

      test('PCP of C', () async {
        final chromas = f.guitar.reassignCombFilter().call(await DataSet().C);

        final pcp = f.filter.interval(4.seconds).call(chromas).first;
        await writer(pcp.l2normalized, title: 'PCP of C');
      });

      test('template of C', () async {
        await writer(
          PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]).l2normalized,
          title: 'Template of C',
        );
      });
    });

    group('scalar', () {
      test('third scaled template of C', () async {
        await writer(
          const ThirdHarmonicChromaScalar(0.2)
              .call(PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]))
              .l2normalized,
          title: 'third scaled template of C',
        );
      });

      test('harmonics scaled template of C', () async {
        await writer(
          HarmonicsChromaScalar()
              .call(PCP(const [1, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0]))
              .l2normalized,
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

    test('scalar, stft vs reassignment', () async {
      const scalar = MagnitudeScalar.dB;
      final data = await DataSet().nutcrackerShort;

      final mags1 = f.magnitude.stft(scalar: scalar).call(data);
      final mags2 = f.magnitude.reassignment(scalar: scalar).call(data);

      await Future.wait([
        writer(mags1, title: '${scalar.name} mags ${f.context}'),
        writer(mags2, title: '${scalar.name} reassignment ${f.context}'),
      ]);
    });

    test('mags, stft vs reassignment', () async {
      final data = await DataSet().sample;

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
        f.guitar.combFilter(),
        f.guitar.reassignCombFilter(),
        f.guitar.reassignment(),
      ];

      await Future.wait(
        estimators.map((e) async => writer(
              e.call(await DataSet().G_Em_Bm_C),
              title: 'chromagram $e ${f.context}',
            )),
      );
    });

    test('common', () async {
      final chromas =
          f.guitar.reassignCombFilter().call(await DataSet().G_Em_Bm_C);
      await writer(chromas, title: 'chromagram');
    });

    test('log scaled', () async {
      final chromas = f.guitar
          .reassignCombFilter(scalar: MagnitudeScalar.ln)
          .call(await DataSet().G_Em_Bm_C);
      await writer(chromas, title: 'chromagram');
    });

    group('filter', () {
      test('threshold 20', () async {
        final filters = [
          const ThresholdFilter(threshold: 20),
          // GaussianFilter.dt(stdDev: 0.2, dt: f.context.dt),
        ];
        final cc = f.guitar.reassignCombFilter();
        var chromas = cc(await DataSet().G_Em_Bm_C);
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
        final cc = f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln);
        var chromas = cc(await DataSet().G_Em_Bm_C);
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

  group('line', () {
    // final f = factory8192_0;
    final f = factory4096_0;
    const writer = LineChartWriter();

    Iterable<Iterable<double>> getScoreWithTime(
      List<Chroma> chroma,
      ScoreCalculator scoreCalculator, {
      double? nanTo,
      double Function(double)? mapper,
    }) {
      Iterable<double> scores = List.generate(
          chroma.length - 1, (i) => scoreCalculator(chroma[i + 1], chroma[i]));

      if (nanTo != null) {
        scores = scores.map((e) => e.isNaN ? nanTo : e);
      }
      if (mapper != null) {
        scores = scores.map(mapper);
      }

      final times =
          List.generate(chroma.length - 1, (i) => f.context.dt * (i + 1));

      return [times, scores];
    }

    test('cosine similarity', () async {
      final chroma = f.guitar.reassignCombFilter().call(await DataSet().sample);
      const scoreCalculator = ScoreCalculator.cosine();

      await writer(
        getScoreWithTime(
          chroma,
          scoreCalculator,
          mapper: (e) => e == 0 ? 1 : e,
        ),
        title: 'cosine similarity HCDF',
      );
    });

    test('tonal centroid', () async {
      final chroma = f.guitar.reassignCombFilter().call(await DataSet().sample);
      const scoreCalculator = ScoreCalculator.cosine(ToTonalCentroid());

      await writer(
        getScoreWithTime(
          chroma,
          scoreCalculator,
          nanTo: 1,
        ),
        title: 'tonal centroid HCDF',
      );
    });
  });
}
