import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:fftea/stft.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domains/chroma.dart';
import 'loader.dart';
import 'log_plot.dart';

class PlotPage extends StatelessWidget {
  const PlotPage({
    super.key,
    this.chunkSize = 2048,
  });

  final int chunkSize;

  List<FlSpot> get _win1 => Window.hanning(chunkSize)
      .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
      .toList();

  List<FlSpot> get _win2 {
    final hanning = Window.hanning(chunkSize);
    final win = hanning.mapIndexed(
        (index, data) => data - (index > 0 ? hanning[index - 1] : 0.0));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  List<FlSpot> get _win3 {
    final hanning = Window.hanning(chunkSize);
    final win =
        hanning.mapIndexed((index, data) => data * (index - chunkSize / 2));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  Future<AudioData> _load() async {
    // final bytesData = await rootBundle.load('assets/evals/guitar_normal_c.wav');
    final bytesData = await rootBundle.load('assets/evals/guitar_note_c3.wav');
    final loader = SimpleAudioLoader(bytes: bytesData.buffer.asUint8List());
    return loader.load();
  }

  List<ScatterSpot> _reassigned(AudioData data) {
    final obj = ReassignmentChromaCalculator(chunkSize: chunkSize);
    final points = obj.tmp(data);
    final maxWeight = maxBy(points, (p0) => p0.weight)!.weight;

    return points
        .map((e) => ScatterSpot(e.x, e.y,
            color: Colors.amber.withOpacity(e.weight / maxWeight)))
        .toList();
  }

  List<ScatterSpot> _magnitudes(AudioData data) {
    final obj = ReassignmentChromaCalculator(chunkSize: chunkSize);
    obj.tmp(data);
    final mags = obj.magnitudes;

    var maxWeight = mags[0][0]; // 初期値を左上の要素として設定

    for (final row in mags) {
      for (final weight in row) {
        if (weight > maxWeight) {
          maxWeight = weight;
        }
      }
    }

    final spots = <ScatterSpot>[];
    final dt = chunkSize / data.sampleRate;
    final df = data.sampleRate / chunkSize;

    for (int i = 0; i < mags.length; ++i) {
      for (int j = 0; j < mags[i].length; ++j) {
        spots.add(
          ScatterSpot(
            i * dt,
            j * df,
            color: Colors.amber.withOpacity(mags[i][j] / maxWeight),
            radius: 4,
          ),
        );
      }
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        // body: LineChart(
        //   LineChartData(
        //     lineBarsData: [
        //       LineChartBarData(
        //         spots: win1,
        //       )
        //     ],
        //   ),
        // ),
        body: FutureBuilder(
          future: _load(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            // return ScatterChart(
            //   ScatterChartData(
            //     scatterSpots: _reassigned(snapshot.data!),
            //   ),
            // );
            // return ScatterChart(
            //   ScatterChartData(
            //     scatterSpots: _magnitudes(snapshot.data!),
            //   ),
            // );
            return LogScatterChart(spots: _magnitudes(snapshot.data!));
          },
        ),
      );
}
