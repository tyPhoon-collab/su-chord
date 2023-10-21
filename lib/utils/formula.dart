import 'dart:math';
import 'dart:typed_data';

const epsilon = 1e-6;

/// a / b in complex
Float64x2 complexDivision(Float64x2 a, Float64x2 b) {
  final c = b.x * b.x + b.y * b.y;
  return Float64x2((a.x * b.x + a.y * b.y) / c, (a.y * b.x - a.x * b.y) / c);
}

double normalDistribution(double x, double mean, double stdDev) {
  final coefficient = 1.0 / (stdDev * sqrt(2 * pi));
  final exponent = -0.5 * pow((x - mean) / stdDev, 2);
  return coefficient * exp(exponent);
}

double Function(double x) normalDistributionClosure(
  double mean,
  double stdDev,
) {
  final coefficient = 1.0 / (stdDev * sqrt(2 * pi));
  return (x) {
    final exponent = -0.5 * pow((x - mean) / stdDev, 2);
    return coefficient * exp(exponent);
  };
}
