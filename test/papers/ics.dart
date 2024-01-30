import 'package:chord/domains/chord.dart';
import 'package:chord/domains/chroma.dart';
import 'package:chord/domains/chroma_mapper.dart';
import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/domains/estimator/pattern_matching.dart';
import 'package:chord/domains/filters/chord_change_detector.dart';
import 'package:chord/domains/magnitudes_calculator.dart';
import 'package:chord/domains/score_calculator.dart';
import 'package:chord/factory.dart';
import 'package:chord/service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

import '../data_set.dart';

void main() {
  test('ics', () async {
    final data = await DataSet().C;
    final f = f_4096;

    final chroma = f.guitar
        .reassignment(scalar: MagnitudeScalar.ln)
        .call(data)
        .average()
        .first;

    final template = PCP.template(Chord.C);
    final template6 = PCP.harmonicTemplate(Chord.C, until: 6);
    final templateLn = PCP.meanTemplate(MeanTemplateContext.harmonicScaling(
      until: 6,
      meanScalar: const LogChromaScalar(),
      detectableChords:
          DetectableChords.conv.where((e) => e.root == Note.C).toSet(),
    ));

    const calcScore = ScoreCalculator.cosine();

    final score = calcScore(chroma, template);
    final score6 = calcScore(chroma, template6);
    final scoreLn = calcScore(chroma, templateLn);

    debugPrint('template   : $score');
    debugPrint('template6  : $score6');
    debugPrint('templateLn : $scoreLn');
    debugPrint('template*  : ${scoreLn * score6}');
  });
}
