import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../config.dart';
import '../../domains/chord_progression.dart';
import '../../domains/estimate.dart';
import '../../js_external.dart';
import '../../service.dart';
import 'loading.dart';
import 'plot.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) {
    final estimator = ref.watch(estimatorProvider);
    return switch (estimator) {
      AsyncData(:final value) => EstimatorPage(estimator: value),
      AsyncError() => const Text('Oops, something unexpected happened'),
      _ => const LoadingPage(),
    };
  }
}

class EstimatorPage extends StatefulWidget {
  const EstimatorPage({super.key, required this.estimator});

  final ChordEstimable estimator;

  @override
  State<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends State<EstimatorPage> {
  late final _estimator = widget.estimator;
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
          builder: (_, value, __) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ChordEstimatorSelector(
                      enable: value == RecorderState.stopped),
                  Expanded(
                    child: StreamBuilder(
                      stream: _recorder.stream,
                      builder: (_, snapshot) {
                        if (!snapshot.hasData) return const SizedBox();
                        //for debug
                        if (value == RecorderState.recording) {
                          _count++;
                        } else {
                          _count = 0;
                          return ChordProgressionView(
                              progression: _progression);
                        }

                        final data =
                            snapshot.data!.downSample(Config.sampleRate);
                        final progression = _estimator.estimate(data, false);

                        return ListView(
                          children: [
                            Text(value.toString()),
                            Text(_count.toString()),
                            Text(data.buffer.length.toString()),
                            ChordProgressionView(progression: progression),
                            if (_estimator is ChromaChordEstimator)
                              Chromagram(
                                chromas: (_estimator as ChromaChordEstimator)
                                    .reducedChromas,
                              ),
                            if (_estimator is Debuggable)
                              for (final text
                                  in (_estimator as Debuggable).debugText())
                                Text(text),
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: RecFloatingActionButton(
          recorder: _recorder,
          onStop: () {
            setState(() {
              _progression = _estimator.flush();
            });
          },
        ),
      );
}

class RecFloatingActionButton extends StatefulWidget {
  const RecFloatingActionButton(
      {super.key, required this.recorder, this.onStop});

  final WebRecorder recorder;
  final VoidCallback? onStop;

  @override
  State<RecFloatingActionButton> createState() =>
      _RecFloatingActionButtonState();
}

class _RecFloatingActionButtonState extends State<RecFloatingActionButton> {
  WebRecorder get _recorder => widget.recorder;

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

class ChordEstimatorSelector extends ConsumerStatefulWidget {
  const ChordEstimatorSelector({
    super.key,
    this.enable = true,
  });

  final bool enable;

  @override
  ConsumerState<ChordEstimatorSelector> createState() =>
      _ChordEstimatorSelectorState();
}

class _ChordEstimatorSelectorState
    extends ConsumerState<ChordEstimatorSelector> {
  @override
  Widget build(BuildContext context) {
    final selectingEstimatorLabel = ref.watch(selectingEstimatorLabelProvider);
    final estimators = ref.watch(estimatorsProvider);

    return DropdownButton(
      items: estimators.keys
          .map((label) => DropdownMenuItem(
                value: label,
                child: Text(label),
              ))
          .toList(),
      value: selectingEstimatorLabel,
      onChanged: widget.enable
          ? (String? value) {
              if (value == null) return;
              ref.read(selectingEstimatorLabelProvider.notifier).change(value);
            }
          : null,
    );
  }
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
