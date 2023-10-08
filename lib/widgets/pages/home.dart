import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../../domains/chord_progression.dart';
import '../../domains/estimator.dart';
import '../../domains/factory.dart';
import '../../js_external.dart';
import '../../recorder.dart';
import '../../service.dart';
import '../chord_view.dart';
import '../recorder_fab.dart';
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
    final context = ref.watch(factoryContextProvider);
    return switch (estimator) {
      AsyncData(:final value) => EstimatorPage(
          estimator: value,
          context: context,
        ),
      AsyncError(:final error) => Text(error.toString()),
      _ => const LoadingPage(),
    };
  }
}

class EstimatorPage extends StatefulWidget {
  const EstimatorPage({
    super.key,
    required this.estimator,
    required this.context,
  });

  final ChordEstimable estimator;
  final EstimatorFactoryContext context;

  @override
  State<EstimatorPage> createState() => _EstimatorPageState();
}

class _EstimatorPageState extends State<EstimatorPage> {
  late final _estimator = widget.estimator;
  final Recorder _recorder = WebRecorder(1.seconds);
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
        drawer: const _HomeDrawer(),
        body: ValueListenableBuilder(
          valueListenable: _recorder.state,
          builder: (_, value, __) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConfigView(recorderState: value),
                  Expanded(
                    child: _progression.isEmpty &&
                            value == RecorderState.stopped
                        ? const _WelcomeView()
                        : StreamBuilder(
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

                              final data = snapshot.data!
                                  .downSample(widget.context.sampleRate);
                              final progression =
                                  _estimator.estimate(data, false);

                              return ListView(
                                children: [
                                  Text(value.name),
                                  Text(_count.toString()),
                                  Text('buffer size: ${data.buffer.length}'),
                                  ChordProgressionView(
                                      progression: progression),
                                  if (_estimator is ChromaChordEstimator)
                                    Chromagram(
                                      chromas:
                                          (_estimator as ChromaChordEstimator)
                                              .filteredChromas,
                                    ),
                                  if (_estimator is Debuggable)
                                    for (final text
                                        in (_estimator as Debuggable)
                                            .debugText())
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

class _HomeDrawer extends StatelessWidget {
  const _HomeDrawer();

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        children: const [
          DrawerHeader(child: Text('Chord')),
          AboutListTile(
            icon: Icon(Icons.library_books_outlined),
          ),
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

class _ConfigView extends StatelessWidget {
  const _ConfigView({required this.recorderState});

  final RecorderState recorderState;

  @override
  Widget build(BuildContext context) => ExpansionTile(
        title: const Text('Config'),
        leading: const Icon(Icons.settings),
        children: [
          ListTile(
            leading: const Icon(Icons.functions_outlined),
            title: const Text('Estimator'),
            trailing: _ChordEstimatorSelector(
              enable: recorderState == RecorderState.stopped,
            ),
          ),
        ],
      );
}

class _ChordEstimatorSelector extends ConsumerStatefulWidget {
  const _ChordEstimatorSelector({this.enable = true});

  final bool enable;

  @override
  ConsumerState<_ChordEstimatorSelector> createState() =>
      _ChordEstimatorSelectorState();
}

class _ChordEstimatorSelectorState
    extends ConsumerState<_ChordEstimatorSelector> {
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
