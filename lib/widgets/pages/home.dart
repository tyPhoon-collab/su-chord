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

  @override
  Future<void> dispose() async {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chord')),
        body: StreamBuilder(
          stream: _recorder.stream,
          builder: (_, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!.downSample(Config.sampleRate);

            return Column(
              children: [
                Text(data.sampleRate.toString()),
                Text(data.buffer.toString()),
              ],
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
