import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../config.dart';
import '../../domains/estimate.dart';
import '../../js_external.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ChordEstimable _estimator = Get.find();
  final _recorder = WebRecorder(1.seconds);
  int _count = 0;

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
              stream: _recorder.stream
                  .map((data) => data.downSample(Config.sampleRate))
                  .map((data) => _estimator.estimate(data, false)),
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                //for debug
                if (value == RecorderState.recording) {
                  _count++;
                } else {
                  _count = 0;
                }

                final progress = snapshot.data!;

                return ListView(
                  children: [
                    Text(value.toString()),
                    Text(_count.toString()),
                    Text(progress.toString()),
                    if (_estimator is Debuggable)
                      for (final text in (_estimator as Debuggable).debugText())
                        Text(text),
                    if (_estimator is ChromaChordEstimator)
                      for (final chroma in (_estimator as ChromaChordEstimator)
                          .reducedChromas
                          .map((e) => e.normalized))
                        Row(
                          children: chroma
                              .map((e) => ColoredBox(
                                  color: Colors.cyan.withOpacity(e),
                                  child: const SizedBox.square(dimension: 10)))
                              .toList(),
                        )
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
              _estimator.flush();
            }
          },
          child: const Icon(Icons.mic),
        ),
      );
}
