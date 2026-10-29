import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/services/portfolio_service.dart';
import 'package:huatlui/services/sell_simulator.dart';

Position holding({
  double quantity = 100,
  double cost = 1000,
  double realized = 125,
}) => Position(
  accountId: 'broker',
  symbol: 'F9D.SI',
  name: 'Boustead',
  assetClass: AssetClass.stock,
  currency: 'SGD',
  quantity: quantity,
  costLocal: cost,
  costBase: cost,
  currentPrice: 12,
  marketValueLocal: quantity * 12,
  marketValueBase: quantity * 12,
  realizedBase: realized,
  realizedLocal: realized,
  dividendsBase: 0,
  totalBoughtBase: cost,
);

void main() {
  const simulator = SellSimulator();
  test('partial sale releases weighted average cost and fees', () {
    final result = simulator.calculate(
      holding: holding(),
      scenario: const SellScenario(quantity: 40, price: 15, fees: 5),
    );
    expect(result.grossProceeds, 600);
    expect(result.netProceeds, 595);
    expect(result.allocatedCost, 400);
    expect(result.profitLoss, 195);
    expect(result.profitLossPct, closeTo(48.75, 1e-9));
    expect(result.breakEvenPrice, closeTo(10.125, 1e-9));
    expect(result.remainingQuantity, 60);
    expect(result.remainingCost, 600);
    expect(result.remainingAverageCost, 10);
  });

  test('full sell closes position and zeroes remaining cost', () {
    final result = simulator.calculate(
      holding: holding(),
      scenario: const SellScenario(quantity: 100, price: 9, fees: 5),
    );
    expect(result.profitLoss, -105);
    expect(result.remainingQuantity, 0);
    expect(result.remainingCost, 0);
    expect(result.remainingAverageCost, 0);
  });

  test('current sale profit excludes prior realized gains after a rebuy', () {
    final position = holding(realized: 900);
    final result = simulator.calculate(
      holding: position,
      scenario: const SellScenario(quantity: 10, price: 11),
    );
    expect(result.profitLoss, 10);
    expect(result.newCumulativeRealizedLocal, 910);
    expect(position.realizedLocal, 900);
    expect(position.quantity, 100);
  });

  test('fees can turn a price gain into a net loss', () {
    final result = simulator.calculate(
      holding: holding(),
      scenario: const SellScenario(quantity: 10, price: 11, fees: 15),
    );
    expect(result.profitLoss, -5);
  });

  test('invalid sell quantity, price and fees are rejected', () {
    for (final scenario in [
      const SellScenario(quantity: 0, price: 11),
      const SellScenario(quantity: 101, price: 11),
      const SellScenario(quantity: 10, price: 0),
      const SellScenario(quantity: 10, price: 11, fees: -1),
      const SellScenario(quantity: double.nan, price: 11),
      const SellScenario(quantity: 10, price: double.infinity),
    ]) {
      expect(() => simulator.calculate(holding: holding(), scenario: scenario),
          throwsArgumentError);
    }
  });

  test('supports fractional holdings without rounding values in calculations', () {
    final result = simulator.calculate(
      holding: holding(quantity: 1.5, cost: 150),
      scenario: const SellScenario(quantity: 0.5, price: 110),
    );
    expect(result.profitLoss, 5);
    expect(result.remainingQuantity, 1);
    expect(result.remainingAverageCost, 100);
  });
}
