import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

typedef CSV = List<List<dynamic>>;

abstract interface class CSVLoader {
  Future<CSV> load();

  static CSVLoader get db {
    const path = 'assets/csv/chord_progression.csv';
    return (kIsWeb || Platform.isIOS || Platform.isAndroid)
        ? const FlutterCSVLoader(path: path)
        : const SimpleCSVLoader(path: path);
  }

  static const corrects = SimpleCSVLoader(
    path: 'assets/csv/correct_only_sharp.csv',
    // ignore: avoid_redundant_argument_values
    eol: '\n',
  );
}

final class SimpleCSVLoader implements CSVLoader {
  const SimpleCSVLoader({
    required this.path,
    this.eol = '\n',
    this.converter,
  });

  final String path;
  final Converter<List<int>, String>? converter;

  final String eol;

  Converter<List<int>, String> get _converter => converter ?? utf8.decoder;

  @override
  Future<CSV> load() async {
    final input = File(path).openRead();
    final csv = await input
        .transform(_converter)
        .transform(CsvToListConverter(eol: eol))
        .toList();

    return csv;
  }
}

final class FlutterCSVLoader implements CSVLoader {
  const FlutterCSVLoader({required this.path});

  final String path;

  @override
  Future<CSV> load() async {
    final csvString = await rootBundle.loadString(path);
    final csv = const CsvToListConverter().convert(csvString);

    return csv;
  }
}
