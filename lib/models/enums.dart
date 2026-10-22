enum AssetClass { stock, etf, unitTrust, reit, bond, cash, other }

enum TradeType { buy, sell }

enum BrokerType { brokerage, roboAdvisor, cpfSrs, custodian, other }

/// Safe enum parsing for stored JSON: unknown/missing values fall back
/// instead of crashing, so an older backup never bricks the app.
T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}
