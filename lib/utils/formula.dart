import 'dart:math';

const epsilon = 1e-6;

double normalDistribution(double x, double mean, double stdDev) {
  final coefficient = 1.0 / (stdDev * sqrt(2 * pi));
  final exponent = -0.5 * pow((x - mean) / stdDev, 2);
  return coefficient * exp(exponent);
}

double Function(double x) normalDistributionClosure(
    double mean, double stdDev) {
  final coefficient = 1.0 / (stdDev * sqrt(2 * pi));
  return (x) {
    final exponent = -0.5 * pow((x - mean) / stdDev, 2);
    return coefficient * exp(exponent);
  };
}
