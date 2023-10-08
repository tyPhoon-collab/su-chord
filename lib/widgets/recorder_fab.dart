import 'package:flutter/material.dart';

import '../recorder.dart';

class RecFloatingActionButton extends StatefulWidget {
  const RecFloatingActionButton(
      {super.key, required this.recorder, this.onStop});

  final Recorder recorder;
  final VoidCallback? onStop;

  @override
  State<RecFloatingActionButton> createState() =>
      _RecFloatingActionButtonState();
}

class _RecFloatingActionButtonState extends State<RecFloatingActionButton> {
  Recorder get _recorder => widget.recorder;

  @override
  Widget build(BuildContext context) => FloatingActionButton(
        onPressed: () {
          if (!_recorder.isRecording) {
            _recorder.start();
          } else {
            _recorder.stop();
            widget.onStop?.call();
          }
        },
        child: ValueListenableBuilder(
          valueListenable: widget.recorder.state,
          builder: (_, value, __) => value == RecorderState.recording
              ? const Icon(Icons.stop)
              : const Icon(Icons.mic),
        ),
      );
}
