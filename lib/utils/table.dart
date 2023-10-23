import 'dart:io';

import 'package:csv/csv.dart';

typedef Row = List<String>;
typedef Header = Row;

class Table extends Iterable<Row> {
  const Table(this._values);

  Table.empty(Header? header) : _values = [if (header != null) header];

  static bool bypass = false;

  final List<Row> _values;

  void clear([remainingHeader = true]) {
    final header = _values.firstOrNull;
    _values.clear();

    if (remainingHeader && header != null) add(header);
  }

  void add(Row row) {
    _values.add(row);
  }

  File toCSV(String path) {
    assert(path.endsWith('.csv'));
    if (bypass) return File(path);

    final file = File(path);
    final contents = const ListToCsvConverter().convert(_values);
    file.writeAsString(contents);

    return file;
  }

  @override
  Iterator<Row> get iterator => _values.iterator;

  List<Row> get headlessValues => _values.sublist(1);
}
