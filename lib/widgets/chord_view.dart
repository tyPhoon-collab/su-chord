import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final display = Theme.of(context).textTheme.displayLarge;
    final detail = Theme.of(context).textTheme.titleMedium;
    return chord == null
        ? Text('No Chord', style: display)
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(chord.toString(), style: display),
              Text(chord!.notes.join(', '), style: detail),
            ],
          );
  }
}
