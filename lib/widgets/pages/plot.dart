import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config.dart';
import '../../domains/chroma.dart';
import '../../log_plot.dart';
import '../../utils/loader.dart';

class PlotPage extends StatefulWidget {
  const PlotPage({super.key});

  @override
  State<PlotPage> createState() => _PlotPageState();
}

class _PlotPageState extends State<PlotPage> {
  List<ScatterSpot> _spots = [];
  AudioData? _audioData;

  late final List<List<ScatterSpot> Function(AudioData)> _getSpotsFunctions = [
    _magnitudes,
    _reassigned,
    // _reassignedHistogram2d,
  ];

  int _spotsFunctionsIndex = 0;
  final double _scatterRadius = 2;

  @override
  void initState() {
    super.initState();
    _load().then((value) {
      _audioData = value;
      _changeSpots(isIncrementIndex: false);
    });
  }

  void _changeSpots({bool isIncrementIndex = true}) {
    if (_audioData == null) return;
    setState(() {
      if (isIncrementIndex) {
        _spotsFunctionsIndex++;
      }
      final index = _spotsFunctionsIndex % _getSpotsFunctions.length;
      _spots = _getSpotsFunctions[index](_audioData!);
    });
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
        body: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_spotsFunctionsIndex.toString()),
            Expanded(
              child: LogScatterChart(spots: _spots),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _changeSpots();
          },
          child: const Icon(Icons.change_circle_outlined),
        ),
      );

  Future<AudioData> _load() async {
    final bytesData = await rootBundle.load('assets/evals/guitar_normal_c.wav');
    // final bytesData =
    //     await rootBundle.load('assets/evals/Halion_CleanGuitarVX/1_青春の影.wav');
    final loader = SimpleAudioLoader(bytes: bytesData.buffer.asUint8List());
    return loader.load(duration: 3, sampleRate: Config.sampleRate);
  }

  // List<FlSpot> get _win1 => Window.hanning(2048)
  //     .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
  //     .toList();
  //
  // List<FlSpot> get _win2 {
  //   final hanning = Window.hanning(2048);
  //   final win = hanning.mapIndexed(
  //       (index, data) => data - (index > 0 ? hanning[index - 1] : 0.0));
  //   return win
  //       .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
  //       .toList();
  // }
  //
  // List<FlSpot> get _win3 {
  //   final hanning = Window.hanning(2048);
  //   final win = hanning
  //       .mapIndexed((index, data) => data * (index - 2048 / 2));
  //   return win
  //       .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
  //       .toList();
  // }

  List<ScatterSpot> _reassigned(AudioData data) {
    final obj = ReassignmentChromaCalculator();
    final points = obj.reassign(data);
    final maxWeight = maxBy(points, (p0) => p0.weight)!.weight;

    return points
        .where((e) => e.weight != 0)
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
