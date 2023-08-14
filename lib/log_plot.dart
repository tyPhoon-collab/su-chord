import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
                reservedSize: 44,
                showTitles: true,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  axisSide: meta.axisSide,
                  child: Text(pow(e, value).toInt().toString()),
                ),
              ),
            ),
          ),
          scatterSpots: _logY(spots),
        ),
      );
}
