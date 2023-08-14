import 'package:collection/collection.dart';
import 'package:fftea/fftea.dart';
import 'package:fftea/stft.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'domains/chroma.dart';
import 'log_plot.dart';
import 'utils/loader.dart';

class PlotPage extends StatefulWidget {
  const PlotPage({
    super.key,
    this.chunkSize = 2048,
  });

  final int chunkSize;

  @override
  State<PlotPage> createState() => _PlotPageState();
}

class _PlotPageState extends State<PlotPage> {
  List<ScatterSpot> _spots = [];
  AudioData? _audioData;

  late final List<List<ScatterSpot> Function(AudioData)> _getSpotsFunctions = [
    _magnitudes,
    _reassigned
  ];

  int _getSpotsFunctionsIndex = 0;

  @override
  void initState() {
    super.initState();
    _load().then((value) {
      _audioData = value;
      _changeSpots();
    });
  }

  void _changeSpots() {
    if (_audioData == null) return;
    setState(() {
      final index = _getSpotsFunctionsIndex++ % _getSpotsFunctions.length;
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
        body: LogScatterChart(spots: _spots),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            _changeSpots();
          },
          child: const Icon(Icons.change_circle_outlined),
        ),
      );

  Future<AudioData> _load() async {
    // final bytesData = await rootBundle.load('assets/evals/guitar_normal_c.wav');
    final bytesData = await rootBundle.load('assets/evals/guitar_note_c3.wav');
    final loader = SimpleAudioLoader(bytes: bytesData.buffer.asUint8List());
    return loader.load();
  }

  List<FlSpot> get _win1 => Window.hanning(widget.chunkSize)
      .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
      .toList();

  List<FlSpot> get _win2 {
    final hanning = Window.hanning(widget.chunkSize);
    final win = hanning.mapIndexed(
        (index, data) => data - (index > 0 ? hanning[index - 1] : 0.0));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  List<FlSpot> get _win3 {
    final hanning = Window.hanning(widget.chunkSize);
    final win = hanning
        .mapIndexed((index, data) => data * (index - widget.chunkSize / 2));
    return win
        .mapIndexed((index, data) => FlSpot(index.toDouble(), data))
        .toList();
  }

  List<ScatterSpot> _reassigned(AudioData data) {
    final obj = ReassignmentChromaCalculator(chunkSize: widget.chunkSize);
    final points = obj.reassign(data);
    final maxWeight = maxBy(points, (p0) => p0.weight)!.weight;

    return points
        .map((e) => ScatterSpot(e.x, e.y,
            color: Colors.amber.withOpacity(e.weight / maxWeight)))
        .toList();
  }

  List<ScatterSpot> _magnitudes(AudioData data) {
    final obj = ReassignmentChromaCalculator(chunkSize: widget.chunkSize);
    obj.reassign(data);
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
    final dt = widget.chunkSize / data.sampleRate;
    final df = data.sampleRate / widget.chunkSize;

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
}
