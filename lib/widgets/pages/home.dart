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
import '../estimator_config_view.dart';
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
  const EstimatorPage({super.key});

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
                  EstimatorConfigView(recorder: _recorder),
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

class _EstimatedView extends ConsumerWidget {
  const _EstimatedView({
    required this.progression,
    required this.estimator,
  });

  final ChordProgression progression;
  final ChordEstimable estimator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      children: [
        ChordProgressionView(progression: progression),
        if (ref.watch(isVisibleDebugProvider)) ...[
          Text(estimator.toString()),
          if (estimator case final HasDebugViews views)
            Wrap(children: views.build())
        ]
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
