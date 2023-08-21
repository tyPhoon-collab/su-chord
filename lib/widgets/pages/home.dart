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
              stream: _recorder.stream,
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                if (value == RecorderState.recording) {
                  _count++;
                } else {
                  _count = 0;
                }

                final data = snapshot.data!.downSample(Config.sampleRate);
                // final data = snapshot.data!;

                final progress = _estimator.estimate(data);

                return Column(
                  children: [
                    Text(value.toString()),
                    // Text(data.sampleRate.toString()),
                    // Text(data.buffer.length.toString()),
                    Text(_count.toString()),
                    Text(progress.toString()),
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
            }
          },
          child: const Icon(Icons.mic),
        ),
      );
}
