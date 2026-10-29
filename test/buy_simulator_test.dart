import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/services/buy_simulator.dart';
import 'package:huatlui/services/fx_service.dart';
import 'package:huatlui/services/portfolio_service.dart';
import 'package:huatlui/models/enums.dart';

Position samplePosition({
  double quantity = 100,
  double cost = 1000,
  double latestPrice = 12,
}) => Position(
  accountId: 'broker',
  symbol: 'TEST.SI',
  name: 'Test Co',
  assetClass: AssetClass.stock,
  currency: 'SGD',
  quantity: quantity,
  costLocal: cost,
  costBase: cost,
  currentPrice: latestPrice,
  marketValueLocal: quantity * latestPrice,
  marketValueBase: quantity * latestPrice,
  realizedBase: 0,
  dividendsBase: 0,
  totalBoughtBase: cost,
);

void main() {
  final sim = BuySimulator(fx: FxService(), baseCurrency: 'SGD');
  test('includes fees in blended average cost', () {
    final result = sim.calculate(
      holding: samplePosition(),
      portfolioMarketValueBase: 5000,
      scenario: const BuyScenario(extraQuantity: 50, buyPrice: 8, fees: 5),
    );
    expect(result.newQuantity, 150);
    expect(result.addedCashLocal, 405);
    expect(result.newCostLocal, 1405);
    expect(result.newAverageCostLocal, closeTo(1405 / 150, 1e-10));
    expect(result.newUnrealizedLocal, 150 * 12 - 1405);
  });

  test('weights use current market prices and assume injected external cash', () {
    final result = sim.calculate(
      holding: samplePosition(),
      portfolioMarketValueBase: 5000,
      scenario: const BuyScenario(extraQuantity: 50, buyPrice: 8),
    );
    expect(result.currentWeightPct, closeTo(24, 1e-10));
    expect(result.projectedWeightPct, closeTo(1800 / 5600 * 100, 1e-10));
  });

  test('rejects zero quantity, negative fees and invalid purchase price', () {
    final position = samplePosition();
    for (final scenario in [
      const BuyScenario(extraQuantity: 0, buyPrice: 8),
      const BuyScenario(extraQuantity: 1, buyPrice: -1),
      const BuyScenario(extraQuantity: 1, buyPrice: 8, fees: -3),
      const BuyScenario(extraQuantity: double.nan, buyPrice: 8),
    ]) {
      expect(
        () => sim.calculate(
          holding: position,
          portfolioMarketValueBase: 5000,
          scenario: scenario,
        ),
        throwsArgumentError,
      );
    }
  });

  test('rejects stale/missing market price', () {
    expect(
      () => sim.calculate(
        holding: samplePosition(latestPrice: 0),
        portfolioMarketValueBase: 5000,
        scenario: const BuyScenario(extraQuantity: 10, buyPrice: 10),
      ),
      throwsArgumentError,
    );
  });

  test('FX conversion affects cash and portfolio weight correctly', () {
    const usd = Position(
      accountId: 'us',
      symbol: 'QQQM',
      name: 'Test ETF',
      assetClass: AssetClass.etf,
      currency: 'USD',
      quantity: 10,
      costLocal: 900,
      costBase: 1206,
      currentPrice: 100,
      marketValueLocal: 1000,
      marketValueBase: 1340,
      realizedBase: 0,
      dividendsBase: 0,
      totalBoughtBase: 1206,
    );
    final result = sim.calculate(
      holding: usd,
      portfolioMarketValueBase: 5000,
      scenario: const BuyScenario(extraQuantity: 2, buyPrice: 90, fees: 1),
    );
    expect(result.addedCashBase, closeTo(181 * 1.34, 1e-9));
    expect(result.projectedWeightPct, closeTo(1608 / 5268 * 100, 1e-9));
  });
}
