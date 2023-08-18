import 'package:chord/domains/equal_temperament.dart';
import 'package:chord/utils/formula.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const epsilon = 0.000001;
  test('normal distribution', () async {
    final hzOfC3 = MusicalScale(Note.C, 3).hz;
    final mu = hzOfC3;
    final sigma = hzOfC3 / 24;
    final ret1 = normalDistribution(mu, mu, sigma);
    final ret2 = normalDistribution(mu + 1, mu, sigma);

    expect(ret2, lessThan(ret1));
  });

  test('normal distribution 3sigma', () async {
    final hzOfC3 = MusicalScale(Note.C, 3).hz;
    final mu = hzOfC3;
    final sigma = hzOfC3 / 24;
    final ret1 = normalDistribution(mu + 3 * sigma, mu, sigma);
    final ret2 = normalDistribution(mu + -3 * sigma, mu, sigma);

    expect(ret1, closeTo(ret2, epsilon));
  });

  test('normal distribution closure', () async {
    final hzOfC3 = MusicalScale(Note.C, 3).hz;
    final mu = hzOfC3;
    final sigma = hzOfC3 / 24;
    final ret1 = normalDistribution(mu + 3 * sigma, mu, sigma);
    final ret2 = normalDistribution(mu + -3 * sigma, mu, sigma);
    final closure = normalDistributionClosure(mu, sigma);

    expect(ret1, closure(mu + 3 * sigma));
    expect(ret2, closure(mu + -3 * sigma));
  });
}
