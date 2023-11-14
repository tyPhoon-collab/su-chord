import 'package:flutter/foundation.dart';

@immutable
class FScore {
  ///正解、誤検知、検知漏れ
  FScore(this.tp, this.fp, this.fn);

  factory FScore.one(double tp) => FScore(tp, 0, 0);

  static final zero = FScore(0, 0, 0);

  final double tp;
  final double fp;
  final double fn;

  late final double score = 2 * precision * recall / (precision + recall);
  late final double precision = tp / (tp + fp);
  late final double recall = tp / (tp + fn);

  FScore operator +(FScore value) =>
      FScore(tp + value.tp, fp + value.fp, fn + value.fn);

  FScore operator /(int length) =>
      FScore(tp / length, fp / length, fn / length);

  @override
  String toString() =>
      'score: $score, precision: $precision, recall: $recall, ($tp, $fp, $fn)';

  String toStringAxFixed(int fractionDigits) =>
      'score: ${score.toStringAsFixed(fractionDigits)}, '
      'precision: ${precision.toStringAsFixed(fractionDigits)}, '
      'recall: ${recall.toStringAsFixed(fractionDigits)}, '
      '(${tp.toStringAsFixed(fractionDigits)}, '
      '${fp.toStringAsFixed(fractionDigits)}, '
      '${fn.toStringAsFixed(fractionDigits)})';

  @override
  int get hashCode => tp.hashCode | fp.hashCode | fn.hashCode;

  @override
  bool operator ==(Object other) {
    if (other is! FScore) return false;
    return tp == other.tp && fp == other.fp && fn == other.fn;
  }
}
