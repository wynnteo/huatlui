/// Currency conversion rates expressed as SGD per unit of foreign currency.
///
/// Default rates are indicative *offline placeholders*, not live quotes.
/// Historical trade records retain their recorded FX rate. Never silently
/// treat an unknown currency as 1:1: that misstates financial totals.
class FxService {
  final Map<String, double> _toSgd;

  FxService([Map<String, double>? toSgd])
      : _toSgd = Map.unmodifiable({
          for (final entry in (toSgd ?? defaultToSgd).entries)
            entry.key.trim().toUpperCase(): entry.value,
        }) {
    for (final entry in _toSgd.entries) {
      if (entry.key.isEmpty ||
          !entry.value.isFinite ||
          entry.value <= 0) {
        throw ArgumentError.value(entry.value, entry.key, 'FX rates must be finite and positive');
      }
    }
  }

  /// Indicative fallback values only; not real-time FX market data.
  static const Map<String, double> defaultToSgd = {
    'SGD': 1.0,
    'USD': 1.34,
    'MYR': 0.30,
    'HKD': 0.172,
    'CNY': 0.185,
    'GBP': 1.70,
    'EUR': 1.46,
  };

  List<String> get supportedCurrencies => _toSgd.keys.toList();

  /// How many units of [to] are obtained from one unit of [from].
  /// Unsupported currencies throw instead of being treated as equivalent.
  double rate(String from, String to) {
    final source = from.trim().toUpperCase();
    final target = to.trim().toUpperCase();
    final f = _toSgd[source];
    final t = _toSgd[target];
    if (f == null) throw ArgumentError.value(from, 'from', 'Unsupported currency');
    if (t == null) throw ArgumentError.value(to, 'to', 'Unsupported currency');
    if (source == target) return 1.0;
    return f / t;
  }

  double convert(double amount, String from, String to) =>
      amount * rate(from, to);

  /// Uses the recorded trade-date rate for the original leg, then converts
  /// from its historical base to the displayed base with the available rate.
  double toBaseHistorical({
    required double amount,
    required double fxRate,
    required String fxBase,
    required String targetBase,
  }) {
    if (!fxRate.isFinite || fxRate <= 0) {
      throw ArgumentError.value(fxRate, 'fxRate', 'Historical FX rate must be finite and positive');
    }
    final recorded = amount * fxRate;
    if (fxBase.trim().toUpperCase() == targetBase.trim().toUpperCase()) {
      return recorded;
    }
    return recorded * rate(fxBase, targetBase);
  }
}
