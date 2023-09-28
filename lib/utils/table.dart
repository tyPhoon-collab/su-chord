import 'dart:io';

import 'package:csv/csv.dart';

typedef Row = List<String>;
typedef Header = Row;

class Table extends Iterable<Row> {
  const Table(this._table);

  Table.empty(Header? header) : _table = [if (header != null) header];

  static bool bypass = false;

  final List<List<String>> _table;

  void clear([remainingHeader = true]) {
    final header = _table.first;
    _table.clear();

    if (remainingHeader) add(header);
  }

  void add(Row row) {
    _table.add(row);
  }

  void toCSV(String path) {
    assert(path.endsWith('.csv'));
    if (bypass) return;

    final file = File(path);
    final contents = const ListToCsvConverter().convert(_table);
    file.writeAsString(contents);
  }

  @override
  Iterator<Row> get iterator => _table.iterator;

  List<Row> get headlessValues => _table.sublist(1);
}
