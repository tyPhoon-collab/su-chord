var musicalLabelType = MusicalLabelType.normal;

enum MusicalLabelType { normal, verbose, jazz }

class MusicalLabel {
  const MusicalLabel(this._label, [this._map = const {}]);

  ///default label string
  final String _label;
  final Map<MusicalLabelType, String> _map;

  String call([MusicalLabelType type = MusicalLabelType.normal]) =>
      _map[type] ?? _label;

  Set<String> get all => {_label, ..._map.values};

  @override
  String toString() => call(musicalLabelType);
}
