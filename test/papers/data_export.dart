import 'package:chord/domains/chroma_calculators/chroma_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/utils/table.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';
import '../writer.dart';

void main() {
  test('spectrum', () async {
    final f = factory8192_0;
    final data = await DataSet().G;

    final mags = f.magnitude.stft().call(data);

    final spec = List.filled(mags.first.length, 0.0);

    for (final mag in mags) {
      for (int i = 0; i < spec.length; i++) {
        spec[i] += mag[i];
      }
    }

    final averageSpec =
        spec.map((e) => e / mags.length).map((e) => e.toString()).toList();

    await Table([averageSpec]).toCSV('assets/csv/osawa/spectrum_G.csv');
  });

  test('spectrogram', () async {
    final f = factory4096_0;
    final mags = f.magnitude.stft().call(await DataSet().G);

    await Table.fromMatrix(mags).toCSV('assets/csv/osawa/spectrogram_G.csv');
  });

  test('reassignment', () async {
    final f = factory4096_0;

    final (points, mags) = ReassignmentCalculator.hanning(
      chunkSize: f.context.chunkSize,
      chunkStride: f.context.chunkStride,
    ).reassign(await DataSet().G);

    logTest(mags.length);

    await Table.fromPoints(points).toCSV('assets/csv/osawa/reassignment_G.csv');
  });
}