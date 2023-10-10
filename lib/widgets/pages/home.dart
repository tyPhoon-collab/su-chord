import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../domains/chord_progression.dart';
import '../../domains/estimator.dart';
import '../../domains/factory.dart';
import '../../recorders/recorder.dart';
import '../../recorders/web_recorder.dart';
import '../../service.dart';
import '../chord_view.dart';
import '../plot_view.dart';
import '../recorder_fab.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  Widget build(BuildContext context) => const EstimatorPage();
}

class EstimatorPage extends StatefulWidget {
  const EstimatorPage({
    super.key,
  });

  @override
  State<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends State<EstimatorPage> {
  final Recorder _recorder = WebRecorder(1.seconds);
  RecorderState? _preState;
  ChordProgression _progression = ChordProgression.empty();

  @override
  Future<void> dispose() async {
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Chord')),
        drawer: const _HomeDrawer(),
        body: ValueListenableBuilder(
          valueListenable: _recorder.state,
          builder: (_, value, __) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _EstimatorConfigView(recorder: _recorder),
                  Consumer(
                    builder: (context, ref, child) {
                      final estimator = ref.watch(estimatorProvider);
                      final context = ref.watch(factoryContextProvider);

                      if (!estimator.hasValue) return const SizedBox();

                      if (_preState == RecorderState.recording &&
                          value == RecorderState.stopped) {
                        _progression = estimator.value!.flush();
                      }

                      final widget = Expanded(
                        child: _preState == null
                            ? const _WelcomeView()
                            : value == RecorderState.stopped
                                ? _EstimatedView(
                                    progression: _progression,
                                    estimator: estimator.value!,
                                  )
                                : _EstimatingStreamView(
                                    recorder: _recorder,
                                    estimator: estimator.value!,
                                    factoryContext: context,
                                  ),
                      );

                      _preState = value;

                      return widget;
                    },
                  ),
                ],
              ),
            );
          },
        ),
        floatingActionButton: RecFloatingActionButton(recorder: _recorder),
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
            child: StreamBuilder(
              stream: recorder.bufferStream,
              builder: (_, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: AmplitudeChart(data: snapshot.data!),
                );
              },
            ),
          ),
          Expanded(
            flex: 6,
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

class _EstimatedView extends StatelessWidget {
  const _EstimatedView({
    required this.progression,
    required this.estimator,
  });

  final ChordProgression progression;
  final ChordEstimable estimator;

  @override
  Widget build(BuildContext context) {
    final e = estimator;
    return ListView(
      children: [
        ChordProgressionView(progression: progression),
        if (e is ChromaChordEstimator) Chromagram(chromas: e.filteredChromas),
        if (e is Debuggable)
          for (final text in (e as Debuggable).debugText()) Text(text),
      ],
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(child: Text('Chord')),
          AboutListTile(icon: Icon(Icons.library_books_outlined)),
        ],
      ),
    );
  }
}

class _WelcomeView extends StatelessWidget {
  const _WelcomeView();

  @override
  Widget build(BuildContext context) => const Center(
        child: Text(
          'Press the record button on the bottom right '
          'to start estimation',
        ),
      );
}

class _EstimatorConfigView extends StatelessWidget {
  const _EstimatorConfigView({required this.recorder});

  final Recorder recorder;

  bool get enable => recorder.state.value == RecorderState.stopped;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: const Text('Config'),
        leading: const Icon(Icons.settings),
        children: [
          ListTile(
            leading: const Icon(Icons.functions_outlined),
            title: const Text('Estimator'),
            trailing: _ChordEstimatorSelector(enable: enable),
          ),
          ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: const Text('Microphone Device'),
            trailing: _MicrophoneDeviceSelector(
              enable: enable,
              recorder: recorder,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.music_note_outlined),
            title: const Text('Detectable Chords'),
            trailing: const Icon(Icons.open_in_new_outlined),
            onTap:
                enable ? () => Get.dialog(const _ChordSettingsDialog()) : null,
          ),
        ],
      );
}

class _ChordSettingsDialog extends ConsumerWidget {
  const _ChordSettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      Builder(builder: (context) {
        final key = GlobalKey<_SelectableDetectableChordsState>();
        return AlertDialog(
          icon: const Icon(Icons.music_note_outlined),
          title: const Text('Chord Settings'),
          content: _SelectableDetectableChords(key: key),
          actions: [
            ElevatedButton(
                onPressed: () {
                  final qualities = key.currentState!.selectingQualities;
                  ref
                      .read(detectableChordsProvider.notifier)
                      .setFromQualities(qualities.toSet());
                  Get.back();
                },
                child: const Text('Apply'))
          ],
        );
      });
}

class _SelectableDetectableChords extends StatefulWidget {
  const _SelectableDetectableChords({super.key});

  @override
  State<_SelectableDetectableChords> createState() =>
      _SelectableDetectableChordsState();
}

class _SelectableDetectableChordsState
    extends State<_SelectableDetectableChords> {
  static final _qualities = DetectableChords.qualities.toList();
  static final _isSelected = List.filled(_qualities.length, true);

  Iterable<String> get selectingQualities =>
      _qualities.whereIndexed((i, _) => _isSelected[i]);

  @override
  Widget build(BuildContext context) => Wrap(
        children: List.generate(
          _qualities.length,
          (i) => ToggleButtons(
            isSelected: [_isSelected[i]],
            onPressed: (_) {
              setState(() {
                _isSelected[i] = !_isSelected[i];
              });
            },
            children: [Text(_qualities[i])],
          ),
        ),
      );
}

class _MicrophoneDeviceSelector extends StatelessWidget {
  const _MicrophoneDeviceSelector({
    this.enable = true,
    required this.recorder,
  });

  final bool enable;
  final Recorder recorder;

  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: recorder.deviceStream,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Text('Please grant mic permission');
        }

        final devices = snapshot.data!;

        return DropdownButton(
          items: devices
              .map((d) => DropdownMenuItem(value: d, child: Text(d.label)))
              .toList(),
          value: devices.current,
          onChanged: enable
              ? (DeviceInfo? value) async {
                  if (value == null) return;
                  await recorder.setDevice(value.id);
                }
              : null,
        );
      });
}

class _ChordEstimatorSelector extends ConsumerWidget {
  const _ChordEstimatorSelector({this.enable = true});

  final bool enable;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectingEstimatorLabel = ref.watch(selectingEstimatorLabelProvider);
    final estimators = ref.watch(estimatorsProvider);

    return DropdownButton(
      items: estimators.keys
          .map((label) => DropdownMenuItem(value: label, child: Text(label)))
          .toList(),
      value: selectingEstimatorLabel,
      onChanged: enable
          ? (String? value) {
              if (value == null) return;
              ref.read(selectingEstimatorLabelProvider.notifier).change(value);
            }
          : null,
    );
  }
}
