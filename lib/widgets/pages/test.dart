import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../js_external.dart';

class TestPage extends StatefulWidget {
  const TestPage({super.key});

  @override
  State<TestPage> createState() => _TestPageState();
}

class _TestPageState extends State<TestPage> {
  final _recorder = WebRecorder(1.seconds);

  @override
  Future<void> dispose() async {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Test Page'),
        ),
        body: StreamBuilder(
          stream: _recorder.stream,
          builder: (_, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final data = snapshot.data!;
            // .downSample(Config.sampleRate);

            return Column(
              children: [
                Text(data.sampleRate.toString()),
                Text(data.buffer.length.toString()),
              ],
            );
          },
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            if (!_recorder.isRecording) {
              await _recorder.start();
            } else {
              _recorder.stop();
            }
          },
          child: const Icon(Icons.mic),
        ),
      );
}
