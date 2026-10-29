import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/services/fx_service.dart';

void main() {
  List<Map<String, Object>> sample() => [
    {'date': '2026-10-28', 'base': 'SGD', 'quote': 'USD', 'rate': 0.77},
    {'date': '2026-10-28', 'base': 'SGD', 'quote': 'MYR', 'rate': 3.3},
    {'date': '2026-10-28', 'base': 'SGD', 'quote': 'HKD', 'rate': 6.0},
    {'date': '2026-10-28', 'base': 'SGD', 'quote': 'CNY', 'rate': 5.5},
    {'date': '2026-10-28', 'base': 'SGD', 'quote': 'GBP', 'rate': 0.59},
    {'date': '2026-10-27', 'base': 'SGD', 'quote': 'EUR', 'rate': 0.65},
  ];

  test('Frankfurter SGD-base quotes are inverted to SGD per currency', () {
    final rates = FxService.parseFrankfurterRates(sample());
    expect(rates['SGD'], 1);
    expect(rates['USD'], closeTo(1 / 0.77, 1e-10));
    expect(rates['MYR'], closeTo(1 / 3.3, 1e-10));
    final fx = FxService(rates);
    expect(fx.convert(100, 'USD', 'SGD'), closeTo(100 / 0.77, 1e-8));
  });

  test('reject partial quote responses', () {
    expect(() => FxService.parseFrankfurterRates(sample().take(2).toList()),
        throwsFormatException);
  });

  test('reject invalid quote values and unexpected base', () {
    final invalid = sample();
    invalid[0]['rate'] = 0;
    expect(() => FxService.parseFrankfurterRates(invalid), throwsFormatException);

    final wrongBase = sample();
    wrongBase[0]['base'] = 'USD';
    expect(() => FxService.parseFrankfurterRates(wrongBase), throwsFormatException);
  });

  test('fallback data is visibly classified as indicative', () {
    final fx = FxService();
    expect(fx.hasLiveData, false);
    expect(fx.isStale, true);
  });
}
