import 'dart:math';

import 'package:collection/collection.dart';
import 'package:fftea/stft.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../domains/chroma.dart';

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

class AmplitudeChart extends StatelessWidget {
  const AmplitudeChart({
    super.key,
    required this.data,
  });

  final List<double> data;

  @override
  Widget build(BuildContext context) {
    return LineChart(
      LineChartData(
        minX: 0,
        maxX: data.length - 1,
        minY: -1,
        maxY: 1,
        backgroundColor: Get.theme.colorScheme.background,
        lineBarsData: [
          LineChartBarData(
            spots:
                data.indexed.map((e) => FlSpot(e.$1.toDouble(), e.$2)).toList(),
            color: Get.theme.colorScheme.primary,
            isCurved: true,
            dotData: const FlDotData(show: false),
          ),
        ],
        lineTouchData: const LineTouchData(enabled: false),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(),
          bottomTitles: AxisTitles(),
        ),
      ),
      duration: 10.milliseconds,
    );
  }
}

class SpectrogramChart extends StatelessWidget {
  const SpectrogramChart({
    super.key,
    required this.magnitudes,
  });

  final Magnitudes magnitudes;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 300,
        height: 300,
        child: CustomPaint(
          painter: _HeatmapPainter(
            data: magnitudes,
            maxValue: magnitudes.map((e) => e.max).max,
          ),
        ),
      );
}

class _HeatmapPainter extends CustomPainter {
  _HeatmapPainter({
    required this.data,
    required this.maxValue,
    // this.minValue = 0,
    Color? color,
  }) : color = color ?? Get.theme.colorScheme.primary;

  final List<List<double>> data;
  final double maxValue;
  final double minValue = 0;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final height = size.height;
    final cellSize = min(width / data.length, height / data[0].length);

    for (int i = 0; i < data.length; i++) {
      for (int j = 0; j < data[0].length; j++) {
        final value = data[i][j];

        // 色を計算する
        final pointColor = Color.lerp(
          color.withAlpha(0),
          color,
          (value - minValue) / (maxValue - minValue),
        )!;

        // ピクセルを描画する
        canvas.drawRect(
          Offset(i * cellSize, j * cellSize) & Size(cellSize, cellSize),
          Paint()..color = pointColor,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_HeatmapPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.maxValue != maxValue ||
        oldDelegate.minValue != minValue ||
        oldDelegate.color != color;
  }
}

class LogScatterChart extends StatelessWidget {
  const LogScatterChart({super.key, required this.spots});

  final List<ScatterSpot> spots;

  List<T> _logY<T extends FlSpot>(List<T> spots) => spots
      .map((e) => e.y == 0 ? e : e.copyWith(y: log(e.y)))
      .cast<T>()
      .toList();

  @override
  Widget build(BuildContext context) => ScatterChart(
        ScatterChartData(
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                reservedSize: 55,
                showTitles: true,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(pow(e, value).round().toString()),
                ),
              ),
            ),
          ),
          scatterSpots: _logY(spots),
        ),
      );
}

///再割り当て時のウィンドウを可視化するためのデバッグ用ページ
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
