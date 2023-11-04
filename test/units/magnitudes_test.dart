import 'package:chord/domains/factory.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  late final f = factory8192_0;

  test('stft', () async {
    final c = f.magnitude.stft();
    final mags = c(await DataSet().G);
    expect(mags, isNotEmpty);
  });

  test('reassignment', () async {
    final c = f.magnitude.reassignment();
    final mags = c(await DataSet().G);
    debugPrint(mags.first.length.toString());
    expect(mags, isNotEmpty);
  });

  test('keep resolution reassignment', () async {
    final c = factory2048_1024.magnitude.reassignment(overrideChunkSize: 8192);
    final mags = c(await DataSet().G);
    debugPrint(mags.first.length.toString());
    expect(mags, isNotEmpty);
  });

  test('reassignment dB', () async {
    final c = f.magnitude.reassignment(scalar: MagnitudeScalar.dB);
    final mags = c(await DataSet().G);
    expect(mags, isNotEmpty);
  });

  // test('same size for different chunkSize and chunkStride', () {
  //   for (final f in [factory8192_0, factory2048_1024]) {
  //     final m1 = f.magnitude.stft().call(data);
  //     final m2 = f.magnitude.reassignment().call(data);
  //
  //     expect(m1.length, m2.length);
  //     expect(m1.first.length, m2.first.length);
  //   }
  // });
}
