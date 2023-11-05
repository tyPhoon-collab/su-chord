import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../domains/chord_progression.dart';
import '../domains/debug.dart';
import '../domains/estimator/estimator.dart';
import '../domains/factory.dart';
import '../recorder_service.dart';
import '../recorders/recorder.dart';
import '../service.dart';
import '../utils/loaders/audio.dart';
import 'chord_view.dart';
import 'config_view.dart';
import 'plot_view.dart';

class EstimatorPage extends ConsumerStatefulWidget {
  const EstimatorPage({super.key});

  @override
  ConsumerState<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends ConsumerState<EstimatorPage> {
  ChordProgression _progression = ChordProgression.empty();

  Color get surface => Get.theme.colorScheme.surfaceVariant;

  Color get onSurface => Get.theme.colorScheme.onSurfaceVariant;

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
                      child: Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: const BorderRadius.only(
                            bottomLeft: Radius.circular(32),
                            bottomRight: Radius.circular(32),
                          ),
                        ),
                        child: DefaultTextStyle.merge(
                          style: TextStyle(color: onSurface),
                          child: value == RecorderState.stopped &&
                                  _progression.isEmpty
                              ? const _WelcomeView()
                              : value == RecorderState.stopped
                                  ? _EstimatedView(
                                      progression: _progression,
                                      estimator: estimator.value!,
                                    )
                                  : _EstimatingStreamView(
                                      stream: recorder.stream,
                                      estimator: estimator.value!,
                                      factoryContext: context,
                                    ),
                        ),
                      ),
                    ),
                    _EstimatorActionBar(
                      recorder: recorder,
                      recorderState: value,
                      onStopped: () {
                        setState(() {
                          _progression = estimator.value!.flush();
                        });
                      },
                      onFileLoaded: () async {
                        await _estimateFromFileWithLoadingView(
                          context.sampleRate,
                          estimator.value!,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      );

  Future<void> _estimateFromFileWithLoadingView(
      int sampleRate, ChordEstimable estimator) async {
    EasyLoading.instance
      ..backgroundColor = surface
      ..loadingStyle = EasyLoadingStyle.custom
      ..indicatorColor = onSurface
      ..textColor = onSurface;
    EasyLoading.show(
      status: 'Estimating...',
      indicator: const Icon(Icons.music_note),
      maskType: EasyLoadingMaskType.black,
      dismissOnTap: false,
    );
    await _estimateFromFile(sampleRate, estimator);
    EasyLoading.dismiss();
  }

  Future<void> _estimateFromFile(
      int sampleRate, ChordEstimable estimator) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['wav'],
    );
    if (result == null) return;

    final data = await SimpleAudioLoader(bytes: result.files.first.bytes).load(
      sampleRate: sampleRate,
    );

    final progression = await compute((data) => estimator.estimate(data), data);

    setState(() {
      _progression = progression;
    });
  }
}

class _EstimatingStreamView extends StatelessWidget {
  const _EstimatingStreamView({
    required this.estimator,
    required this.factoryContext,
    required this.stream,
  });

  final Stream<AudioData> stream;
  final ChordEstimable estimator;
  final EstimatorFactoryContext factoryContext;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: StreamBuilder(
        stream: stream,
        builder: (_, snapshot) {
          if (!snapshot.hasData) return const SizedBox();

          // log(snapshot.requireData.buffer.take(10).toString());
          // log(snapshot.requireData.buffer.length.toString());

          final data = snapshot.data!.downSample(factoryContext.sampleRate);

          final progression = estimator.estimate(data, false);

          return _EstimatedView(
            progression: progression,
            estimator: estimator,
          );
        },
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
          ChordProgressionView(
            progression: ref.watch(isSimplifyChordProgressionProvider)
                ? progression.simplify()
                : progression,
          ),
          SingleChildScrollView(
            child: _EstimatorDebugView(
              visible: ref.watch(isVisibleDebugProvider),
              estimator: estimator,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstimatorDebugView extends ConsumerWidget {
  const _EstimatorDebugView({
    required this.visible,
    required this.estimator,
  });

  final bool visible;
  final ChordEstimable estimator;

  HasDebugViews get views => estimator as HasDebugViews;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      estimator is HasDebugViews
          ? Wrap(
              spacing: 8.0,
              runSpacing: 8.0,
              children: [
                DebugChip(
                  titleText: 'Estimator Details',
                  builder: (_) => Text(estimator.toString()),
                ),
                ...views.build(),
                DebugChip(
                  titleText: 'Amplitude',
                  builder: (_) => StreamBuilder(
                    stream: ref.watch(globalRecorderProvider).stream,
                    builder: (_, snapshot) => SizedBox(
                      height: 64,
                      child: AmplitudeChart(
                        data: snapshot.data?.buffer ??
                            Float64List.fromList(const []),
                      ),
                    ),
                  ),
                ),
              ],
            )
          : const SizedBox();
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
  const _EstimatorActionBar({
    required this.recorder,
    required this.recorderState,
    this.onStopped,
    this.onFileLoaded,
  });

  final Recorder recorder;
  final RecorderState recorderState;
  final VoidCallback? onStopped;
  final VoidCallback? onFileLoaded;

  bool get isStopped => recorderState == RecorderState.stopped;

  @override
  Widget build(BuildContext context) {
    final crossFadeState =
        isStopped ? CrossFadeState.showFirst : CrossFadeState.showSecond;
    final animationDuration = 200.milliseconds;

    return ButtonBar(
      alignment: MainAxisAlignment.center,
      buttonPadding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        IconButton.filledTonal(
          onPressed: isStopped ? onFileLoaded : null,
          icon: const Icon(Icons.folder_outlined),
        ),
        IconButton.filled(
          iconSize: 32,
          padding: const EdgeInsets.all(24),
          onPressed: () async {
            if (isStopped) {
              recorder.start();
            } else {
              await recorder.stop();
              onStopped?.call();
            }
          },
          icon: AnimatedCrossFade(
            firstChild: const Icon(Icons.mic_none_outlined),
            secondChild: const Icon(Icons.stop_outlined),
            crossFadeState: crossFadeState,
            duration: animationDuration,
          ),
        ),
        IconButton.filledTonal(
          onPressed: isStopped
              ? () {
                  Get.bottomSheet(
                    const SafeArea(
                      child: Column(
                        children: [
                          SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [CloseButton(), SizedBox(width: 16)],
                          ),
                          Expanded(child: ConfigView())
                        ],
                      ),
                    ),
                    backgroundColor: Get.theme.colorScheme.background,
                  );
                }
              : null,
          icon: const Icon(Icons.settings_outlined),
        ),
      ],
    );
  }
}
