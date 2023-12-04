import 'dart:io';

import 'package:csv/csv.dart';

import 'histogram.dart';

typedef Row = List<String>;
typedef Header = Row;

class Table extends Iterable<Row> {
  const Table(this._values, {this.header});

  Table.empty(this.header) : _values = [];

  Table.fromMatrix(Iterable<Iterable<num>> data, {this.header})
      : _values = data.map((e) => e.map((e) => e.toString()).toList()).toList();

  Table.fromPoints(Iterable<Point> points)
      : header = ['x', 'y', 'c'],
        _values = points
            .map((e) => [
                  e.x.toString(),
                  e.y.toString(),
                  e.weight.toString(),
                ])
            .toList();

  static bool bypass = false;

  final List<Row> _values;
  final Header? header;

  void clear() {
    _values.clear();
  }

  void add(Row row) {
    _values.add(row);
  }

  Future<File> toCSV(String path) async {
    assert(path.endsWith('.csv'));
    if (bypass) return File(path);

    final file = await File(path).create(recursive: true);
    final contents = const ListToCsvConverter().convert([
      if (header != null) header,
      ..._values,
    ]);
    await file.writeAsString(contents);

    return file;
  }

  @override
  Iterator<Row> get iterator => _values.iterator;
}
