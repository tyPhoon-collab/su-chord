import 'package:chord/domains/analyzer.dart';
import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimator/estimator.dart';
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
import 'util.dart';
import 'writer.dart';

void main() {
  group('bar', () {
    const write = BarChartWriter();

    test('parts of mags', () async {
      final f = factory4096_0;
      final mc = f.magnitude.stft(scalar: MagnitudeScalar.ln);

      final mags = mc(await DataSet().G);

      final floatIndex = mc.indexOfFrequency(
        const Pitch(Note.G, 3).toHz(),
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

      group('spotting', () {
        Future<void> plotSpot(String path, int index, {String? title}) async {
          final data =
              await SimpleAudioLoader(path: path).load(sampleRate: 22050);

          final cc =
              factory4096_0.guitar.reassignment(scalar: MagnitudeScalar.ln);

          await writer(
            average(cc(data.cutEvaluationAudioByIndex(index)))
                .first
                .l2normalized,
            title: title,
          );
        }

        test('12 A Dadd9', () async {
          await plotSpot(
            'assets/evals/Halion_CleanGuitarVX/12_1039_Halion_CleanGuitarVX.wav',
            10,
          );
        });

        test('11 D Cadd9', () async {
          await plotSpot('assets/evals/HojoGuitar/11_Hojo.wav', 1);
        });
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
        test('template C', () async {
          final chord = Chord.parse('C');
          await writer(
            chord.unitPCP.l2normalized,
            // title: 'Template of $chord',
          );
        });

        group('scalar', () {
          test('third scaled template of C', () async {
            final chord = Chord.parse('C');

            await writer(
              const OnlyThirdHarmonicChromaScalar(0.2)
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
                // title: '4 harmonics scaled template of $chord',
              );
            });

            test('6th', () async {
              final chord = Chord.parse('C');

              await writer(
                HarmonicsChromaScalar(until: 6)
                    .call(chord.unitPCP)
                    .l2normalized,
                // title: '6 harmonics scaled template of $chord',
              );
            });

            test('0.8 6th', () async {
              final chord = Chord.parse('C');

              await writer(
                HarmonicsChromaScalar(factor: 0.8, until: 6)
                    .call(chord.unitPCP)
                    .l2normalized,
                // title: '6 harmonics scaled template of $chord',
              );
            });
          });
        });

        group('mean', () {
          test('mean C', () async {
            final pcp = MeanTemplateContext.harmonicScaling(
              until: 6,
              templates: ChromaChordEstimator.defaultDetectableChords
                  .where((e) => e.root == Note.C)
                  .toSet(),
            ).meanTemplateChromas.keys.first;
            await writer(pcp.l2normalized, title: 'mean template C');
          });

          test('ln mean C', () async {
            final pcp = MeanTemplateContext.harmonicScaling(
              until: 6,
              templates: ChromaChordEstimator.defaultDetectableChords
                  .where((e) => e.root == Note.C)
                  .toSet(),
              meanScalar: const LogChromaScalar(),
            ).meanTemplateChromas.keys.first;
            await writer(pcp.l2normalized, title: 'mean template ln C');
          });
        });
      });

      group('real data', () {
        final f = factory4096_0;
        final cc = f.guitar.reassignment(scalar: MagnitudeScalar.ln);

        Future<void> plot(List<Chroma> chromas, {String? title}) async {
          final pcp = average(chromas).first;
          await writer(
            pcp.l2normalized,
            title: title,
          );
        }

        test('r G', () async {
          await plot(cc(await DataSet().G));
        });

        test('r C', () async {
          await plot(cc(await DataSet().C));
        });

        test('r F#m7b5', () async {
          await plot(
            cc(await const SimpleAudioLoader(
              path: 'assets/evals/Halion_CleanGuitarVX/2_東京-03.wav',
            ).load().then((value) => value.cutEvaluationAudioByIndex(2))),
          );
        });
      });
    });
  });

  group('spec', () {
    group('spot', () {
      test('C F', () async {
        final f = factory4096_2048;

        final data = await const SimpleAudioLoader(
                path: 'assets/evals/RealStrat/5_涙の天使に-01.wav')
            .load(sampleRate: 22050)
            .then((value) => value.cutEvaluationAudioByIndex(1));

        const scalar = MagnitudeScalar.ln;
        final magsSTFT = f.magnitude.stft(scalar: scalar).call(data);
        final magsReassignment =
            f.magnitude.reassignment(scalar: scalar).call(data);

        final writer = SpecChartWriter(LibROSASpecShowContext.of(f.context));

        await Future.wait([
          writer(magsSTFT),
          writer(magsReassignment),
        ]);
      });
    });
    group('plot mags and sparse', () {
      Future<void> plot(
        EstimatorFactory factory, {
        MagnitudeScalar scalar = MagnitudeScalar.none,
        num? yMin,
        num? yMax,
      }) async {
        final writer =
            SpecChartWriter(LibROSASpecShowContext.of(factory.context));

        final data = await DataSet().G_Em_Bm_C;

        final magsSTFT = factory.magnitude.stft(scalar: scalar).call(data);
        final magsReassignment =
            factory.magnitude.reassignment(scalar: scalar).call(data);

        await Future.wait([
          writer(
            magsSTFT,
            title: '${factory.context.chunkSize} stft $scalar',
            yMin: yMin,
            yMax: yMax,
          ),
          writer(
            magsReassignment,
            title: '${factory.context.chunkSize} reassignment $scalar',
            yMin: yMin,
            yMax: yMax,
          ),
        ]);
      }

      test('1024', () async {
        await plot(factory1024_0);
      });
      test('16384', () async {
        await plot(factory16384_0);
      });
      test('4096', () async {
        await plot(factory4096_0);
      });
      test('4096, ln', () async {
        await plot(factory4096_0, scalar: MagnitudeScalar.ln);
      });
      test('4096, dB', () async {
        await plot(
          factory4096_0,
          scalar: MagnitudeScalar.dB,
          yMax: 2200,
        );
      });
    });
  });
  group('hist 2d', () {
    final f = factory4096_0;
    const writer = Hist2DChartWriter();

    test('parts of reassignment', () async {
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
    final writer = SpecChartWriter.chroma(LibROSASpecShowContext.of(f.context));

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
      group('sample silent', () {
        final cc = f.guitar.reassignment(scalar: MagnitudeScalar.ln);

        test('cosine similarity', () async {
          final chroma = cc(await DataSet().sampleSilent);
          const scoreCalculator = ScoreCalculator.cosine();
          final (time, score) = getTimeAndScore(
            f.context.deltaTime,
            chroma,
            scoreCalculator,
            mapper: (e) => e == 0 ? 1 : e,
          );

          await writer(time, score, title: 'HCDF cosine similarity');
        });

        test('tonal centroid', () async {
          final chroma = cc(await DataSet().sampleSilent);
          const scoreCalculator = ScoreCalculator.cosine(ToTonalCentroid());
          final (time, score) = getTimeAndScore(
            f.context.deltaTime,
            chroma,
            scoreCalculator,
            nanTo: 1,
          );

          await writer(time, score, title: 'HCDF tonal centroid');
        });
        test('tonal interval vector', () async {
          final chroma = cc(await DataSet().sampleSilent);
          const scoreCalculator =
              ScoreCalculator.cosine(ToTonalIntervalVector.musical());

          final (time, score) = getTimeAndScore(
            f.context.deltaTime,
            chroma,
            scoreCalculator,
            nanTo: 1,
          );

          await writer(time, score, title: 'HCDF tonal interval vector');
        });
      });
    });
    group('LTAS', () {
      final f = factory4096_0;
      final calc = f.magnitude.stft();

      // const xMin = 0;
      // const xMax = 6000;

      final bins = ChromaContext.guitar.toEqualTemperamentBin();
      final xMin = bins.first;
      final xMax = bins.last;

      hideTitle = true;

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
          xMin: xMin,
          xMax: xMax,
          xLabel: 'Frequency',
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
          xMin: xMin,
          xMax: xMax,
          xLabel: 'Frequency',
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
          xMin: xMin,
          xMax: xMax,
          xLabel: 'Frequency',
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
          xMin: xMin,
          xMax: xMax,
          xLabel: 'Frequency',
        );
      });
    });
  });
}
