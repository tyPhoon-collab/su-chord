import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../domains/chord.dart';
import '../domains/chord_progression.dart';

class ChordProgressionView extends StatelessWidget {
  const ChordProgressionView(this._progression, {super.key});

  final ChordProgression<Chord> _progression;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(_progression.toString()),
          ChordView(chord: _progression.lastOrNull?.chord),
        ],
      );
}

class ChordView extends StatelessWidget {
  const ChordView({super.key, required this.chord});

  final Chord? chord;

  TextStyle? get style => Get.textTheme.displayLarge;

  @override
  Widget build(BuildContext context) => chord == null
      ? Text('No Chord', style: style)
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(chord.toString(), style: style),
            Text(
              chord!.notes.join(', '),
              style: Get.textTheme.titleMedium,
            ),
          ],
        );
}
