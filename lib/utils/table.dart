import 'dart:io';

import 'package:csv/csv.dart';

typedef Row = List<String>;
typedef Header = Row;

class Table extends Iterable<Row> {
  const Table(this._values);

  Table.empty(Header? header) : _values = [if (header != null) header];

  static bool bypass = false;

  final List<List<String>> _values;

  void clear([remainingHeader = true]) {
    final header = _values.first;
    _values.clear();

    if (remainingHeader) add(header);
  }

  void add(Row row) {
    _values.add(row);
  }

  void toCSV(String path) {
    assert(path.endsWith('.csv'));
    if (bypass) return;

    final file = File(path);
    final contents = const ListToCsvConverter().convert(_values);
    file.writeAsString(contents);
  }

  @override
  Iterator<Row> get iterator => _values.iterator;

  List<Row> get headlessValues => _values.sublist(1);
}
