import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../domains/chord_progression.dart';
import '../../domains/estimator.dart';
import '../../domains/factory.dart';
import '../../recorders/recorder.dart';
import '../../service.dart';
import '../chord_view.dart';
import '../plot_view.dart';

class EstimatorPage extends ConsumerStatefulWidget {
  const EstimatorPage({super.key});

  @override
  ConsumerState<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends ConsumerState<EstimatorPage> {
  ChordProgression _progression = ChordProgression.empty();

  @override
  Widget build(BuildContext context) => Builder(
        builder: (_) {
          final recorder = ref.watch(globalRecorderProvider);
          final estimator = ref.watch(estimatorProvider);
          final context = ref.watch(factoryContextProvider);

          if (!estimator.hasValue) return const SizedBox();

          return ValueListenableBuilder(
            valueListenable: recorder.state,
            builder: (_, value, __) {
              return Center(
                child: Column(
                  children: [
                    Expanded(
                      child:
                          value == RecorderState.stopped && _progression.isEmpty
                              ? const _WelcomeView()
                              : value == RecorderState.stopped
                                  ? _EstimatedView(
                                      progression: _progression,
                                      estimator: estimator.value!,
                                    )
                                  : _EstimatingStreamView(
                                      recorder: recorder,
                                      estimator: estimator.value!,
                                      factoryContext: context,
                                    ),
                    ),
                    _EstimatorActionBar(
                      recorder: recorder,
                      onStop: () {
                        setState(() {
                          _progression = estimator.value!.flush();
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
}

class _EstimatingStreamView extends StatelessWidget {
  const _EstimatingStreamView({
    required this.recorder,
    required this.estimator,
    required this.factoryContext,
  });

  final Recorder recorder;
  final ChordEstimable estimator;
  final EstimatorFactoryContext factoryContext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: Builder(builder: (context) {
              var progression = ChordProgression.empty();
              return StreamBuilder(
                stream: recorder.stream,
                builder: (_, snapshot) {
                  if (!snapshot.hasData) return const SizedBox();

                  final data =
                      snapshot.data!.downSample(factoryContext.sampleRate);

                  return FutureBuilder(
                    future: compute(
                        (data) => estimator.estimate(data, false), data),
                    builder: (_, snapshot) {
                      if (snapshot.hasData) {
                        progression = snapshot.data!;
                      }
                      return _EstimatedView(
                        progression: progression,
                        estimator: estimator,
                      );
                    },
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EstimatedView extends ConsumerWidget {
  const _EstimatedView({
    required this.progression,
    required this.estimator,
  });

  final ChordProgression progression;
  final ChordEstimable estimator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ListView(
        padding: const EdgeInsets.all(16),
        shrinkWrap: true,
        children: [
          ChordProgressionView(progression: progression),
          if (ref.watch(isVisibleDebugProvider)) ...[
            Text(estimator.toString()),
            if (estimator case final HasDebugViews views)
              Wrap(children: views.build())
          ]
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context) => Center(
        child: Text(
          "Let's start playing chord!",
          style: Get.textTheme.titleLarge,
        ),
      );
}

class _EstimatorActionBar extends StatelessWidget {
  const _EstimatorActionBar({required this.recorder, this.onStop});

  final Recorder recorder;
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.all(16),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: ValueListenableBuilder(
            valueListenable: recorder.state,
            builder: (_, value, __) {
              final crossFadeState = value == RecorderState.stopped
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond;
              final duration = 200.milliseconds;

              return Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (value != RecorderState.stopped)
                    Expanded(
                      child: StreamBuilder(
                        stream: recorder.bufferStream,
                        builder: (_, snapshot) {
                          if (!snapshot.hasData) return const SizedBox();

                          return Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: SizedBox(
                              height: 46,
                              child: AmplitudeChart(
                                data: snapshot.data!,
                                backgroundColor: Get.theme.colorScheme.surface,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ButtonBar(
                    children: [
                      //   ...[
                      //     IconButton.filledTonal(
                      //       onPressed: recorder.pause,
                      //       icon: const Icon(Icons.pause),
                      //     )
                      //   ].map(
                      //     (e) => AnimatedCrossFade(
                      //       firstChild: const SizedBox(),
                      //       secondChild: e,
                      //       crossFadeState: crossFadeState,
                      //       duration: duration,
                      //     ),
                      //   ),
                      IconButton.filledTonal(
                        onPressed: () {
                          if (value == RecorderState.stopped) {
                            recorder.start();
                          } else {
                            recorder.stop();
                            onStop?.call();
                          }
                        },
                        icon: AnimatedCrossFade(
                          firstChild: const Icon(Icons.mic),
                          secondChild: const Icon(Icons.stop),
                          crossFadeState: crossFadeState,
                          duration: duration,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      );
}
