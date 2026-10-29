import 'portfolio_service.dart';

/// Pure, read-only forecast of a hypothetical sell in the holding's currency.
/// Mirrors PortfolioService's weighted-average cost release for sells.
class SellScenario {
  final double quantity;
  final double price;
  final double fees;

  const SellScenario({
    required this.quantity,
    required this.price,
    this.fees = 0,
  });
}

class SellScenarioResult {
  final double grossProceeds;
  final double netProceeds;
  final double allocatedCost;
  final double profitLoss;
  final double profitLossPct;
  final double breakEvenPrice;
  final double remainingQuantity;
  final double remainingCost;
  final double remainingAverageCost;
  final double newCumulativeRealizedLocal;

  const SellScenarioResult({
    required this.grossProceeds,
    required this.netProceeds,
    required this.allocatedCost,
    required this.profitLoss,
    required this.profitLossPct,
    required this.breakEvenPrice,
    required this.remainingQuantity,
    required this.remainingCost,
    required this.remainingAverageCost,
    required this.newCumulativeRealizedLocal,
  });
}

class SellSimulator {
  const SellSimulator();

  SellScenarioResult calculate({
    required Position holding,
    required SellScenario scenario,
  }) {
    final quantity = scenario.quantity;
    final price = scenario.price;
    final fees = scenario.fees;
    if (!holding.isOpen ||
        !holding.quantity.isFinite || holding.quantity <= 0 ||
        !holding.costLocal.isFinite || holding.costLocal < 0 ||
        !holding.realizedLocal.isFinite ||
        !quantity.isFinite || quantity <= 0 ||
        !price.isFinite || price <= 0 ||
        !fees.isFinite || fees < 0) {
      throw ArgumentError('Invalid holding or sell scenario.');
    }
    // Allow only rounding residue, not material oversells. User-entered
    // quantities must not exceed the actual position.
    if (quantity > holding.quantity) {
      throw ArgumentError('Cannot sell more shares than currently held.');
    }

    final fraction = quantity / holding.quantity;
    final allocatedCost = holding.costLocal * fraction;
    final gross = quantity * price;
    final net = gross - fees;
    final gain = net - allocatedCost;
    final balance = holding.quantity - quantity;
    final remainingCost = balance == 0 ? 0.0 : holding.costLocal - allocatedCost;
    final breakEven = (allocatedCost + fees) / quantity;
    final cumulativeRealized = holding.realizedLocal + gain;
    if (![fraction, allocatedCost, gross, net, gain, remainingCost,
          breakEven, cumulativeRealized].every((v) => v.isFinite)) {
      throw ArgumentError('Scenario exceeds supported numeric range.');
    }
    return SellScenarioResult(
      grossProceeds: gross,
      netProceeds: net,
      allocatedCost: allocatedCost,
      profitLoss: gain,
      profitLossPct: allocatedCost > 0 ? gain / allocatedCost * 100 : 0,
      breakEvenPrice: breakEven,
      remainingQuantity: balance,
      remainingCost: remainingCost,
      remainingAverageCost: balance > 0 ? remainingCost / balance : 0,
      newCumulativeRealizedLocal: cumulativeRealized,
    );
  }
}
