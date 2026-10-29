import 'fx_service.dart';
import 'portfolio_service.dart';

/// Read-only simulation; does not create, persist or modify trades.
class BuyScenario {
  final double extraQuantity;
  final double buyPrice;
  final double fees;
  const BuyScenario({
    required this.extraQuantity,
    required this.buyPrice,
    this.fees = 0,
  });
}

class BuyScenarioResult {
  final double newQuantity;
  final double newAverageCostLocal;
  final double newCostLocal;
  final double addedCashLocal;
  final double addedCashBase;
  final double newMarketValueLocal;
  final double newMarketValueBase;
  final double newUnrealizedLocal;
  final double currentWeightPct;
  final double projectedWeightPct;

  const BuyScenarioResult({
    required this.newQuantity,
    required this.newAverageCostLocal,
    required this.newCostLocal,
    required this.addedCashLocal,
    required this.addedCashBase,
    required this.newMarketValueLocal,
    required this.newMarketValueBase,
    required this.newUnrealizedLocal,
    required this.currentWeightPct,
    required this.projectedWeightPct,
  });
}

class BuySimulator {
  final FxService fx;
  final String baseCurrency;
  const BuySimulator({required this.fx, required this.baseCurrency});

  BuyScenarioResult calculate({
    required Position holding,
    required double portfolioMarketValueBase,
    required BuyScenario scenario,
  }) {
    final q = scenario.extraQuantity;
    final price = scenario.buyPrice;
    final fee = scenario.fees;
    if (!q.isFinite || q <= 0 || !price.isFinite || price <= 0 ||
        !fee.isFinite || fee < 0) {
      throw ArgumentError('Enter positive quantity and price, and non-negative fees.');
    }
    if (!holding.isOpen) {
      throw ArgumentError('Simulation requires an open holding.');
    }
    if (!holding.currentPrice.isFinite || holding.currentPrice <= 0 ||
        !holding.quantity.isFinite || holding.quantity <= 0 ||
        !holding.costLocal.isFinite || holding.costLocal < 0 ||
        !portfolioMarketValueBase.isFinite || portfolioMarketValueBase <= 0) {
      throw ArgumentError('Invalid current holdings or market valuation.');
    }

    final cash = q * price + fee;
    final addedBase = fx.convert(cash, holding.currency, baseCurrency);
    final currentBaseIncrement =
        fx.convert(q * holding.currentPrice, holding.currency, baseCurrency);
    final qty = holding.quantity + q;
    final newCost = holding.costLocal + cash;
    final newMarketLocal = qty * holding.currentPrice;
    final newMarketBase = holding.marketValueBase + currentBaseIncrement;
    final newPortfolioValue = portfolioMarketValueBase + currentBaseIncrement;
    if (!cash.isFinite || !addedBase.isFinite || !newCost.isFinite ||
        !newMarketBase.isFinite || !newPortfolioValue.isFinite ||
        newPortfolioValue <= 0) {
      throw ArgumentError('Scenario exceeds supported numeric range.');
    }

    return BuyScenarioResult(
      newQuantity: qty,
      newAverageCostLocal: newCost / qty,
      newCostLocal: newCost,
      addedCashLocal: cash,
      addedCashBase: addedBase,
      newMarketValueLocal: newMarketLocal,
      newMarketValueBase: newMarketBase,
      newUnrealizedLocal: newMarketLocal - newCost,
      currentWeightPct: holding.marketValueBase / portfolioMarketValueBase * 100,
      projectedWeightPct: newMarketBase / newPortfolioValue * 100,
    );
  }
}
