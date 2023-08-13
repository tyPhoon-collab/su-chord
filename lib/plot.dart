import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:fftea/stft.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domains/chroma.dart';
import 'loader.dart';

class PlotPage extends StatelessWidget {
  const PlotPage({
    super.key,
    this.chunkSize = 2048,
  });

  final int chunkSize;

  List<FlSpot> get win1 => Window.hanning(chunkSize)
      .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
      .toList();

  List<FlSpot> get win2 {
    final hanning = Window.hanning(chunkSize);
    final win = hanning.mapIndexed(
        (index, data) => data - (index > 0 ? hanning[index - 1] : 0.0));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  List<FlSpot> get win3 {
    final hanning = Window.hanning(chunkSize);
    final win =
        hanning.mapIndexed((index, data) => data * (index - chunkSize / 2));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  Future<List<ScatterSpot>> get sca async {
    // final bytesData = await rootBundle.load('assets/evals/guitar_note_c3.wav');
    final bytesData = await rootBundle.load('assets/evals/guitar_normal_c.wav');
    final loader = SimpleAudioLoader(bytes: bytesData.buffer.asUint8List());
    final data = await loader.load();

    final obj = ReassignmentChromaCalculator();
    final points = obj.tmp(data);
    final maxWeight = maxBy(points, (p0) => p0.weight)!.weight;

    return points
        .map((e) => ScatterSpot(e.x, e.y,
            color: Colors.amber.withOpacity(e.weight / maxWeight)))
        .toList();
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
          future: sca,
          builder: (_, snapshot) => ScatterChart(
            ScatterChartData(
              scatterSpots: snapshot.data ?? [],
            ),
          ),
        ),
      );
}
