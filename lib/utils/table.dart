import 'dart:io';

import 'package:csv/csv.dart';

typedef Header = List<String>;

class Table {
  Table(this._table);

  Table.empty(Header? header) : _table = [if (header != null) header];

  final List<List<String>> _table;

  void clear() {
    _table.clear();
  }

  void add(List<String> row) {
    _table.add(row);
  }

  void toCSV(String path) {
    final file = File(path);
    final contents = const ListToCsvConverter().convert(_table);
    file.writeAsString(contents);
  }
}
