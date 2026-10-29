import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/services/fx_service.dart';

void main() {
  test('uses a configured FX cross-rate rather than assuming parity', () {
    final fx = FxService({'SGD': 1, 'USD': 1.3, 'EUR': 1.5});
    expect(fx.rate('USD', 'SGD'), closeTo(1.3, 1e-12));
    expect(fx.convert(100, 'USD', 'EUR'), closeTo(86.6666666667, 1e-8));
  });

  test('currency codes normalize case and whitespace', () {
    final fx = FxService({'SGD': 1, 'USD': 1.3});
    expect(fx.rate(' usd ', ' sgd '), closeTo(1.3, 1e-12));
    expect(fx.rate('usd', 'USD'), 1);
  });

  test('unknown currency never silently converts 1:1', () {
    final fx = FxService({'SGD': 1, 'USD': 1.3});
    expect(() => fx.rate('XYZ', 'XYZ'), throwsArgumentError);
    expect(() => fx.convert(100, 'XYZ', 'SGD'), throwsArgumentError);
    expect(() => fx.rate('SGD', 'ABC'), throwsArgumentError);
  });

  test('invalid configured rates are rejected', () {
    expect(() => FxService({'SGD': 1, 'USD': 0}), throwsArgumentError);
    expect(() => FxService({'SGD': 1, 'USD': double.nan}), throwsArgumentError);
    expect(() => FxService({'SGD': 1, 'USD': double.infinity}), throwsArgumentError);
  });

  test('historical recorded exchange rate is preserved', () {
    final fx = FxService({'SGD': 1, 'USD': 1.3, 'EUR': 1.5});
    expect(
      fx.toBaseHistorical(amount: 100, fxRate: 1.4, fxBase: 'SGD', targetBase: 'SGD'),
      closeTo(140, 1e-12),
    );
    expect(
      fx.toBaseHistorical(amount: 100, fxRate: 1.4, fxBase: 'SGD', targetBase: 'EUR'),
      closeTo(140 / 1.5, 1e-12),
    );
    expect(
      () => fx.toBaseHistorical(amount: 100, fxRate: 0, fxBase: 'SGD', targetBase: 'SGD'),
      throwsArgumentError,
    );
  });

  test('mutating external rate map cannot change calculations', () {
    final rates = <String, double>{'SGD': 1, 'USD': 1.3};
    final fx = FxService(rates);
    rates['USD'] = 9;
    expect(fx.rate('USD', 'SGD'), closeTo(1.3, 1e-12));
  });
}
