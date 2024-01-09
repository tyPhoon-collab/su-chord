import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
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

    final (points, mags) =
        (f.magnitude.reassignment() as ReassignmentMagnitudesCalculator)
            .reassignmentCalculator
            .reassign(await DataSet().G);

    logTest(mags.length);

    await Table.fromPoints(points).toCSV('assets/csv/osawa/reassignment_G.csv');
  });

  test('pcp', () async {
    final f = factory4096_0;

    final cc = f.guitar.reassignment(scalar: MagnitudeScalar.ln);
    final pcp = average(cc(await DataSet().C)).map((e) => e.l2normalized);
    await Table.fromMatrix(pcp).toCSV('assets/csv/osawa/pcp_C.csv');
  });
}
