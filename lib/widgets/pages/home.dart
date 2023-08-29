import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config.dart';
import '../../domains/chord_progression.dart';
import '../../domains/estimate.dart';
import '../../js_external.dart';
import 'plot.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChordEstimable _estimator = Get.find();
  final _recorder = WebRecorder(1.seconds);
  int _count = 0;
  ChordProgression _progression = ChordProgression.empty();

  @override
  Future<void> dispose() async {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chord')),
        body: ValueListenableBuilder(
          valueListenable: _recorder.state,
          builder: (BuildContext context, value, _) {
            return StreamBuilder(
              stream: _recorder.stream,
              builder: (_, snapshot) {
                if (!snapshot.hasData) {
                  return ChordProgressionView(progression: _progression);
                }
                //for debug
                if (value == RecorderState.recording) {
                  _count++;
                } else {
                  _count = 0;
                }

                final data = snapshot.data!.downSample(Config.sampleRate);
                final progression = _estimator.estimate(data, false);

                return ListView(
                  children: [
                    Text(value.toString()),
                    Text(_count.toString()),
                    Text(data.buffer.length.toString()),
                    ChordProgressionView(progression: progression),
                    if (_estimator is ChromaChordEstimator)
                      Chromagram(
                        chromas:
                            (_estimator as ChromaChordEstimator).reducedChromas,
                      ),
                    if (_estimator is Debuggable)
                      for (final text in (_estimator as Debuggable).debugText())
                        Text(text),
                  ],
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (!_recorder.isRecording) {
              _recorder.start();
            } else {
              _recorder.stop();
              setState(() {
                _progression = _estimator.flush();
              });
            }
          },
          child: const Icon(Icons.mic),
        ),
      );
}

class ChordProgressionView extends StatelessWidget {
  const ChordProgressionView({super.key, required this.progression});

  final ChordProgression progression;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(progression.toString()),
          Text(
            progression.lastOrNull.toString(),
            style: Get.textTheme.headlineLarge,
          ),
        ],
      );
}
