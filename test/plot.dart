import 'package:chord/domains/analyzer.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/filters/filter.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/loaders/audio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import 'data_set.dart';
import 'writer.dart';

void main() {
  group('bar', () {
    const write = BarChartWriter();

    test('parts of mags', () async {
      final f = factory4096_0;
      final mc = f.magnitude.stft(scalar: MagnitudeScalar.ln);

      final mags = mc(await DataSet().G);

      final floatIndex = mc.indexOfFrequency(
        const MusicalScale(Note.G, 3).toHz(),
        f.context.sampleRate,
      );
      final i = floatIndex.toInt();
      final freq = mc.frequency(i, f.context.sampleRate);

      debugPrint(floatIndex.toString());
      debugPrint(freq.toString());

      await write(mags[3].sublist(i - 8, i + 8), title: 'parts of mags');
    });

    group('pcp', () {
      const writer = PCPChartWriter();

      test('different window size', () async {
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
                average(cc(await DataSet().G)).first.l2normalized,
                title: 'pcp of G, ${f.context} $cc',
              )
        ]);
      });

      test('spotting', () async {
        final f = factory4096_0;
        final data = await const SimpleAudioLoader(
                path:
                    'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav')
            .load(sampleRate: 22050);

        final cc = f.guitar.reassignment(scalar: MagnitudeScalar.ln);

        await writer(
          average(cc(data.cutEvaluationAudioByIndex(10))).first.l2normalized,
          title: '12-Dadd9',
        );
      });

      test('spot compare', () async {
        final factories = [factory8192_0, factory4096_0];
        final data = await const SimpleAudioLoader(
                path:
                    'assets/evals/Halion_CleanGuitarVX/13_1119_Halion_CleanGuitarVX.wav')
            .load(
          sampleRate: 22050,
          duration: 4.1,
          offset: 12,
        );

        await Future.wait([
          for (final f in factories)
            for (final cc in [
              f.guitar.reassignCombFilter(),
              f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
            ])
              writer(
                average(cc.call(data)).first.l2normalized,
                title: 'pcp of G $cc ${f.context}',
              )
        ]);
      });

      group('template', () {
        test('template', () async {
          final chord = Chord.parse('C');
          await writer(chord.unitPCP.l2normalized, title: 'Template of $chord');
        });

        group('scalar', () {
          test('third scaled template of C', () async {
            final chord = Chord.parse('C');

            await writer(
              const ThirdHarmonicChromaScalar(0.2)
                  .call(chord.unitPCP)
                  .l2normalized,
              title: 'third scaled template of $chord',
            );
          });

          group('harmonics scaled', () {
            test('4th', () async {
              final chord = Chord.parse('C');

              await writer(
                HarmonicsChromaScalar().call(chord.unitPCP).l2normalized,
                title: '4 harmonics scaled template of $chord',
              );
            });

            test('6th', () async {
              final chord = Chord.parse('C');

              await writer(
                HarmonicsChromaScalar(until: 6)
                    .call(chord.unitPCP)
                    .l2normalized,
                title: '6 harmonics scaled template of $chord',
              );
            });
          });
        });
      });

      group('real data', () {
        final f = factory4096_0;

        test('PCP of G', () async {
          final chromas = f.guitar.reassignCombFilter().call(await DataSet().G);

          final pcp = average(chromas).first;
          await writer(pcp.l2normalized, title: 'PCP of G');
        });

        test('PCP of C', () async {
          final chromas = f.guitar.reassignCombFilter().call(await DataSet().C);

          final pcp = average(chromas).first;
          await writer(pcp.l2normalized, title: 'PCP of C');
        });
      });
    });
  });

  group('spec', () {
    final f = factory4096_0;
    final writer = SpecChartWriter(
      sampleRate: f.context.sampleRate,
      chunkSize: f.context.chunkSize,
      chunkStride: f.context.chunkStride,
    );

    test('scalar, stft vs reassignment', () async {
      const scalar = MagnitudeScalar.dB;
      final data = await DataSet().G_Em_Bm_C;

      final mags1 = f.magnitude.stft(scalar: scalar).call(data);
      final mags2 = f.magnitude.reassignment(scalar: scalar).call(data);

      await Future.wait([
        writer(
          mags1,
          title: '${scalar.name} mags ${f.context}',
          yMax: 2200,
        ),
        writer(
          mags2,
          title: '${scalar.name} reassignment ${f.context}',
          yMax: 2200,
        ),
      ]);
    });

    test('mags, stft vs reassignment', () async {
      final data = await DataSet().G_Em_Bm_C;

      final mags1 = f.magnitude.stft().call(data);
      final mags2 = f.magnitude.reassignment().call(data);

      await Future.wait([
        writer(mags1, title: 'mags ${f.context}'),
        writer(mags2, title: 'reassignment ${f.context}'),
      ]);
    });

    test('parts of reassignment', () async {
      const writer = Hist2DChartWriter();
      final (points, mags) = ReassignmentCalculator.hanning(
        chunkSize: f.context.chunkSize,
        chunkStride: f.context.chunkStride,
      ).reassign(await DataSet().G);
      await writer(
        points,
        xBin: List.generate(mags.length, (i) => i * f.context.deltaTime),
        yBin: ChromaContext.guitar.toEqualTemperamentBin(),
        title: 'parts of reassignment',
      );
    });
  });

  group('chromagram', () {
    final f = factory4096_0;
    final writer = SpecChartWriter.chroma(
      sampleRate: f.context.sampleRate,
      chunkSize: f.context.chunkSize,
      chunkStride: f.context.chunkStride,
    );

    test('chromagram compare', () async {
      final estimators = [
        f.guitar.stftCombFilter(scalar: MagnitudeScalar.ln),
        f.guitar.reassignCombFilter(scalar: MagnitudeScalar.ln),
        f.guitar.reassignment(),
        f.guitar.reassignment(scalar: MagnitudeScalar.ln),
        f.guitar.reassignment(isReassignFrequency: false),
        f.guitar.reassignment(
          scalar: MagnitudeScalar.ln,
          isReassignFrequency: false,
        ),
      ];

      await Future.wait(
        estimators.map((e) async => writer(
              e.call(await DataSet().G_Em_Bm_C),
              title: 'chromagram $e ${f.context}',
            )),
      );
    });

    test('common', () async {
      final chromas = f.guitar
          .reassignment(scalar: MagnitudeScalar.ln)
          .call(await DataSet().G_Em_Bm_C);
      await writer(chromas, title: 'chromagram');
    });

    group('filter', () {
      test('threshold', () async {
        const filter = ThresholdFilter(30);
        final chromas = filter(f.guitar
            .reassignment(scalar: MagnitudeScalar.ln)
            .call(await DataSet().G_Em_Bm_C));
        await writer(chromas, title: 'chromagram threshold');
      });
      test('gaussian', () async {
        final filter = GaussianFilter.dt(stdDev: 0.5, dt: f.context.deltaTime);
        final chromas = filter(f.guitar
            .reassignment(scalar: MagnitudeScalar.ln)
            .call(await DataSet().G_Em_Bm_C));
        await writer(chromas, title: 'chromagram gaussian');
      });
      test('multi', () async {
        final filters = [
          GaussianFilter.dt(stdDev: 0.5, dt: f.context.deltaTime),
          const ThresholdFilter(30),
        ];
        final chromas = filters.fold(
          f.guitar
              .reassignment(scalar: MagnitudeScalar.ln)
              .call(await DataSet().G_Em_Bm_C),
          (value, filter) => filter(value),
        );
        await writer(chromas, title: 'chromagram multi');
      });
    });
  });

  group('line', () {
    const writer = LineChartWriter();

    group('HCDF', () {
      final f = factory4096_0;

      (List<double> time, List<double> score) getScore(
        List<Chroma> chroma,
        ScoreCalculator scoreCalculator, {
        double? nanTo,
        double Function(double)? mapper,
      }) {
        Iterable<double> scores = List.generate(
          chroma.length - 1,
          (i) => scoreCalculator(chroma[i + 1], chroma[i]),
        );

        if (nanTo != null) {
          scores = scores.map((e) => e.isNaN ? nanTo : e);
        }
        if (mapper != null) {
          scores = scores.map(mapper);
        }

        final times = List.generate(
            chroma.length - 1, (i) => f.context.deltaTime * (i + 1));

        return (times, scores.toList());
      }

      group('sample silent', () {
        final cc = f.guitar.reassignment(scalar: MagnitudeScalar.ln);

        test('cosine similarity', () async {
          final chroma = cc(await DataSet().sampleSilent);
          const scoreCalculator = ScoreCalculator.cosine();
          final score = getScore(
            chroma,
            scoreCalculator,
            mapper: (e) => e == 0 ? 1 : e,
          );

          await writer(score.$1, score.$2, title: 'HCDF cosine similarity');
        });

        test('tonal centroid', () async {
          final chroma = cc(await DataSet().sampleSilent);
          const scoreCalculator = ScoreCalculator.cosine(ToTonalCentroid());
          final score = getScore(
            chroma,
            scoreCalculator,
            nanTo: 1,
          );

          await writer(score.$1, score.$2, title: 'HCDF tonal centroid');
        });
        test('tonal interval vector', () async {
          final chroma = cc(await DataSet().sampleSilent);
          const scoreCalculator =
              ScoreCalculator.cosine(ToTonalIntervalVector.musical());

          final score = getScore(
            chroma,
            scoreCalculator,
            nanTo: 1,
          );

          await writer(score.$1, score.$2, title: 'HCDF tonal interval vector');
        });
      });
    });
    group('LTAS', () {
      final f = factory4096_0;
      final calc = f.magnitude.stft();
      const xMax = 6000;

      test('A', () async {
        final ltas = LTASCalculator(magnitudesCalculable: calc)
            .call(await DataSet().concat('assets/evals/Halion_CleanGuitarVX'));

        await writer(
          List.generate(
            ltas.length,
            (index) => calc.frequency(index, f.context.sampleRate),
          ),
          ltas,
          title: 'LTAS A',
          xMin: 0,
          xMax: xMax,
        );
      });

      test('B', () async {
        final ltas = LTASCalculator(magnitudesCalculable: calc).call(
            await DataSet().concat('assets/evals/Halion_CleanStratGuitar'));

        await writer(
          List.generate(
            ltas.length,
            (index) => calc.frequency(index, f.context.sampleRate),
          ),
          ltas,
          title: 'LTAS B',
          xMin: 0,
          xMax: xMax,
        );
      });

      test('C', () async {
        final ltas = LTASCalculator(magnitudesCalculable: calc)
            .call(await DataSet().concat('assets/evals/HojoGuitar'));

        await writer(
          List.generate(
            ltas.length,
            (index) => calc.frequency(index, f.context.sampleRate),
          ),
          ltas,
          title: 'LTAS C',
          xMin: 0,
          xMax: xMax,
        );
      });

      test('D', () async {
        final ltas = LTASCalculator(magnitudesCalculable: calc)
            .call(await DataSet().concat('assets/evals/RealStrat'));

        await writer(
          List.generate(
            ltas.length,
            (index) => calc.frequency(index, f.context.sampleRate),
          ),
          ltas,
          title: 'LTAS D',
          xMin: 0,
          xMax: xMax,
        );
      });
    });
  });
}
