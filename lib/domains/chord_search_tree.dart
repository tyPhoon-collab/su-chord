import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

import '../utils/tree.dart';
import 'chord.dart';

export '../service.dart';

typedef SearchTree = TreeKeyValueNode<Note, Iterable<Chord>>;

abstract class SearchTreeContext {
  const SearchTreeContext(this.detectableChords);

  final Set<Chord> detectableChords;

  int get maxCombination => 4;

  Iterable<Chord> possibleChords(Notes notes);

  SearchTree buildSearchTree(Note firstNote) {
    final root = TreeKeyValueNode(
      firstNote,
      possibleChords([firstNote]),
    );

    _addChild(root, [firstNote]);
    return root;
  }

  void _addChild(SearchTree node, Notes registeredNotes) {
    if (registeredNotes.length == maxCombination) return;

    for (final note
        in Note.sharpNotes.whereNot((e) => registeredNotes.contains(e))) {
      final notes = [note, ...registeredNotes];
      final childNode = node.addChild(note, possibleChords(notes));
      _addChild(childNode, notes);
    }
  }
}

class Possible extends SearchTreeContext {
  const Possible(super.detectableChords);

  @override
  Iterable<Chord> possibleChords(Notes notes) {
    return detectableChords.where(
        (e) => notes.every((note) => e.noteIndexes.contains(note.noteIndex)));
  }
}

class Precise extends SearchTreeContext {
  const Precise(super.detectableChords);

  @override
  Iterable<Chord> possibleChords(Notes notes) {
    final noteIndexes = notes.map((e) => e.noteIndex).toSet();

    return detectableChords.where((e) => setEquals(e.noteIndexes, noteIndexes));
  }
}

class RoughPossible extends SearchTreeContext {
  const RoughPossible(super.detectableChords);

  @override
  Iterable<Chord> possibleChords(Notes notes) {
    final noteIndexes = notes.map((e) => e.noteIndex);
    return detectableChords.where(
        (e) => e.noteIndexes.every((index) => noteIndexes.contains(index)));
  }
}

Iterable<Chord> Function(Notes notes) searchChordsClosure(
    SearchTreeContext context) {
  final searchTreeEntry = {
    for (final note in Note.sharpNotes) note: context.buildSearchTree(note)
  };

  return (notes) {
    if (notes.isEmpty) return const [];
    var root = searchTreeEntry[notes.first];

    for (final note in notes.skip(1).take(context.maxCombination - 1)) {
      root = root?.getChild(note);
    }
    return root?.value ?? const [];
  };
}
