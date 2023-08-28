import 'package:collection/collection.dart';
import 'package:fftea/stft.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domains/chroma.dart';

class Chromagram extends StatelessWidget {
  const Chromagram({
    super.key,
    required this.chromas,
    this.height = 120,
    this.color = Colors.deepOrange,
  });

  final Iterable<Chroma> chromas;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final values = chromas.map((e) => e.normalized).flattened.toList();
    return values.isEmpty
        ? SizedBox(height: height)
        : SizedBox(
            height: height,
            child: Builder(builder: (context) {
              final crossAxisCount = chromas.first.length;
              final size = height / crossAxisCount;
              return GridView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: values.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount),
                itemBuilder: (_, i) => Container(
                  width: size,
                  height: size,
                  color: color.withOpacity(values[i]),
                ),
              );
            }),
          );
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
