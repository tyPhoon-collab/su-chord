import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';

import '../recorder_service.dart';
import '../recorders/recorder.dart';
import '../service.dart';

class ConfigView extends ConsumerWidget {
  const ConfigView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recorder = ref.watch(globalRecorderProvider);

    return ListView(
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
        const ListTile(
          leading: Icon(Icons.functions_outlined),
          title: Text('Estimator'),
          subtitle: _ChordEstimatorSelector(),
        ),
        CheckboxListTile(
          value: ref.watch(isSimplifyChordProgressionProvider),
          onChanged: (value) {
            if (value == null) return;
            ref.read(isSimplifyChordProgressionProvider.notifier).toggle();
          },
          title: const Text('Simplify Chord Progression'),
          secondary: const Icon(Icons.short_text_outlined),
        ),
        if (recorder case final InputDeviceSelectable selectable)
          ListTile(
            leading: const Icon(Icons.mic_none_outlined),
            title: const Text('Microphone Device'),
            trailing: _MicrophoneDeviceSelector(
              recorder: selectable,
              onRequest: recorder.request,
            ),
          ),
        ListTile(
          leading: const Icon(Icons.music_note_outlined),
          title: const Text('Chord Settings'),
          trailing: const Icon(Icons.open_in_new_outlined),
          onTap: () => Get.dialog(const _ChordSettingsDialog()),
        ),
      ],
    );
  }
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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const ListTile(
                  leading: Icon(Icons.code),
                  title: Text('Detectable Chords'),
                  dense: true,
                ),
                _SelectableDetectableChords(key: key),
              ],
            ),
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
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          children: List.generate(
            _qualities.length,
            (i) {
              final isRequiredChordType = _notSelectableIndexes.contains(i);
              return ToggleButtons(
                disabledColor: isRequiredChordType ? primary : null,
                disabledBorderColor: isRequiredChordType ? primary : null,
                isSelected: [_isSelected[i]],
                constraints: const BoxConstraints(
                  minHeight: 32,
                  minWidth: 52,
                ),
                onPressed: !isRequiredChordType
                    ? (_) {
                        setState(() {
                          _isSelected[i] = !_isSelected[i];
                        });
                      }
                    : null,
                children: [Text(_qualities[i])],
              );
            },
          ),
        ),
        ButtonBar(
          children: [
            IconButton.outlined(
              onPressed: () {
                setState(() {
                  _isSelected = _filledIsSelected(true);
                });
              },
              icon: const Icon(Icons.select_all),
            ),
            IconButton.outlined(
              onPressed: () {
                setState(() {
                  _isSelected = _filledIsSelected(false);
                });
              },
              icon: const Icon(Icons.deselect),
            ),
          ],
        ),
      ],
    );
  }
}

class _MicrophoneDeviceSelector extends StatelessWidget {
  const _MicrophoneDeviceSelector({
    required this.onRequest,
    required this.recorder,
  });

  final InputDeviceSelectable recorder;
  final Function onRequest;

  @override
  Widget build(BuildContext context) => StreamBuilder(
      stream: recorder.deviceStream,
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return TextButton(
            onPressed: () {
              onRequest();
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
          onChanged: (DeviceInfo? value) async {
            if (value == null) return;
            await recorder.setDevice(value.id);
          },
        );
      });
}

class _ChordEstimatorSelector extends ConsumerWidget {
  const _ChordEstimatorSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      itemHeight: null,
      isExpanded: true,
      onChanged: (String? value) {
        if (value == null) return;
        ref.read(selectingEstimatorLabelProvider.notifier).change(value);
      },
    );
  }
}
