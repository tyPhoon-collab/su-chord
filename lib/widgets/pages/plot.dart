import 'package:collection/collection.dart';
import 'package:fftea/stft.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../domains/chroma.dart';
import '../../log_plot.dart';
import '../../utils/loader.dart';

class PlotPage extends StatelessWidget {
  const PlotPage({super.key});

  static const double _scatterRadius = 2;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: FutureBuilder(
          future: _load(),
          builder: (_, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!;
            return Row(
              children: [
                Expanded(child: LogScatterChart(spots: _magnitudes(data))),
                Expanded(child: LogScatterChart(spots: _reassigned(data))),
                // Expanded(child: _buildChart(_magnitudes(data))),
                // Expanded(child: _buildChart(_reassigned(data))),
              ],
            );
          },
        ),
      );

  Widget _buildChart(List<ScatterSpot> spots) =>
      ScatterChart(ScatterChartData(scatterSpots: spots));

  Future<AudioData> _load() async {
    final bytesData =
        await rootBundle.load('assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');

    // final bytesData = await rootBundle.load('assets/evals/guitar_normal_c.wav');
    final loader = SimpleAudioLoader(bytes: bytesData.buffer.asUint8List());
    return loader.load(duration: 3, sampleRate: Config.sampleRate);

    // final loader = DeltaAudioLoader();
    // return loader.load();
  }

  List<ScatterSpot> _reassigned(AudioData data) {
    final obj = ReassignmentChromaCalculator();
    final points = obj.reassign(data);
    final maxWeight = maxBy(points, (p0) => p0.weight)?.weight ?? 0;

    return points
        .map((e) => ScatterSpot(
              e.x,
              e.y,
              color: Colors.amber.withOpacity(e.weight / maxWeight),
              radius: _scatterRadius,
            ))
        .toList();
  }

  List<ScatterSpot> _reassignedHistogram2d(AudioData data) {
    final obj = ReassignmentChromaCalculator();
    obj.chroma(data);
    final mags = obj.histogram2d!.values;

    var maxWeight = mags[0][0];

    for (final row in mags) {
      for (final weight in row) {
        if (weight > maxWeight) {
          maxWeight = weight;
        }
      }
    }

    final spots = <ScatterSpot>[];

    for (int i = 0; i < mags.length; ++i) {
      for (int j = 0; j < mags[i].length; ++j) {
        if (mags[i][j] == 0) continue;
        spots.add(
          ScatterSpot(
            i * 4,
            j * obj.df,
            color: Colors.amber.withOpacity(mags[i][j] / maxWeight),
            radius: _scatterRadius,
          ),
        );
      }
    }

    return spots;
  }

  List<ScatterSpot> _magnitudes(AudioData data) {
    final obj = ReassignmentChromaCalculator();
    obj.reassign(data);
    final mags = obj.magnitudes;

    var maxWeight = mags[0][0];

    for (final row in mags) {
      for (final weight in row) {
        if (weight > maxWeight) {
          maxWeight = weight;
        }
      }
    }

    final spots = <ScatterSpot>[];

    for (int i = 0; i < mags.length; ++i) {
      for (int j = 0; j < mags[i].length; ++j) {
        if (mags[i][j] == 0) continue;
        spots.add(
          ScatterSpot(
            i * obj.dt,
            j * obj.df,
            color: Colors.amber.withOpacity(mags[i][j] / maxWeight),
            radius: _scatterRadius,
          ),
        );
      }
    }

    return spots;
  }
}

class WindowPlotPage extends StatelessWidget {
  const WindowPlotPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(),
        body: Row(
          children: [
            Expanded(child: _buildChart(_win1)),
            Expanded(child: _buildChart(_win2)),
            Expanded(child: _buildChart(_win3)),
          ],
        ),
      );

  List<FlSpot> get _win1 => Window.hanning(2048)
      .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
      .toList();

  Widget _buildChart(List<FlSpot> spots) =>
      LineChart(LineChartData(lineBarsData: [LineChartBarData(spots: spots)]));

  List<FlSpot> get _win2 {
    final hanning = Window.hanning(2048);
    final win = hanning.mapIndexed(
        (index, data) => data - (index > 0 ? hanning[index - 1] : 0.0));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  List<FlSpot> get _win3 {
    final hanning = Window.hanning(2048);
    final win = hanning.mapIndexed((index, data) => data * (index - 2048 / 2));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }
}
