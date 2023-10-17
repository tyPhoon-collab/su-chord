import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../recorder_service.dart';
import '../recorders/recorder.dart';
import '../service.dart';

class ConfigView extends StatelessWidget {
  const ConfigView({super.key});

  @override
  Widget build(BuildContext context) => Consumer(
        builder: (context, ref, child) {
          final recorder = ref.watch(globalRecorderProvider);

          return ExpansionTile(
            title: const Text('Config'),
            leading: const Icon(Icons.settings),
            shape: Border.all(color: Colors.transparent),
            children: [
              CheckboxListTile(
                value: ref.watch(isVisibleDebugProvider),
                onChanged: (value) {
                  if (value == null) return;
                  ref.read(isVisibleDebugProvider.notifier).toggle();
                },
                title: const Text('Show Debug View'),
                secondary: const Icon(Icons.auto_graph_sharp),
              ),
              ValueListenableBuilder(
                valueListenable: recorder.state,
                builder: (_, value, __) {
                  final enable = value == RecorderState.stopped;

                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        enabled: enable,
                        leading: const Icon(Icons.functions_outlined),
                        title: const Text('Estimator'),
                        trailing: _ChordEstimatorSelector(enable: enable),
                      ),
                      ListTile(
                        enabled: enable,
                        leading: const Icon(Icons.mic_none_outlined),
                        title: const Text('Microphone Device'),
                        trailing: _MicrophoneDeviceSelector(
                          enable: enable,
                          recorder: recorder,
                        ),
                      ),
                      ListTile(
                        enabled: enable,
                        leading: const Icon(Icons.music_note_outlined),
                        title: const Text('Chord Settings'),
                        trailing: const Icon(Icons.open_in_new_outlined),
                        onTap: () => Get.dialog(const _ChordSettingsDialog()),
                      ),
                    ],
                  );
                },
              ),
            ],
          );
        },
      );
}

class _ChordSettingsDialog extends ConsumerWidget {
  const _ChordSettingsDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) => Builder(
        builder: (_) {
          final key = GlobalKey<_SelectableDetectableChordsState>();

          return AlertDialog(
            icon: const Icon(Icons.music_note_outlined),
            title: const Text('Chord Settings'),
            content: _SelectableDetectableChords(key: key),
            actions: [
              TextButton(onPressed: Get.back, child: const Text('Back')),
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
            scrollable: true,
          );
        },
      );
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
  static List<bool> _isSelected = _filledIsSelected(true);

  static final _notSelectableIndexes = [0, 1];

  static List<bool> _filledIsSelected(bool value) {
    final list = List.filled(_qualities.length, value);
    for (final i in _notSelectableIndexes) {
      list[i] = true;
    }
    return list;
  }

  Iterable<String> get selectingQualities =>
      _qualities.whereIndexed((i, _) => _isSelected[i]);

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(),
          Wrap(
            children: List.generate(
              _qualities.length,
              (i) => ToggleButtons(
                isSelected: [_isSelected[i]],
                onPressed: !_notSelectableIndexes.contains(i)
                    ? (_) {
                        setState(() {
                          _isSelected[i] = !_isSelected[i];
                        });
                      }
                    : null,
                children: [Text(_qualities[i])],
              ),
            ),
          ),
          Row(
            children: [
              const Spacer(),
              Text(
                'Cannot deselected Major and Minor chord types.',
                style: TextStyle(color: Get.theme.colorScheme.outline),
              ),
            ],
          ),
          ButtonBar(
            children: [
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isSelected = _filledIsSelected(true);
                  });
                },
                child: const Text('Select All'),
              ),
              OutlinedButton(
                onPressed: () {
                  setState(() {
                    _isSelected = _filledIsSelected(false);
                  });
                },
                child: const Text('Deselect All'),
              ),
            ],
          ),
          const Divider(),
        ],
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
          return TextButton(
            onPressed: () {
              recorder.request();
            },
            child: const Text('Please grant mic permission'),
          );
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
