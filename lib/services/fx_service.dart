/// POC exchange rates: the value of 1 unit of each currency in SGD.
/// Replace [defaultToSgd] with a real rate source later (an API, cached by
/// date); nothing outside this class needs to change.
class FxService {
  final Map<String, double> _toSgd;

  FxService([Map<String, double>? toSgd]) : _toSgd = toSgd ?? defaultToSgd;

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

  /// Today's rate: how many [to] you get for 1 [from].
  double rate(String from, String to) {
    if (from == to) return 1.0;
    final f = _toSgd[from];
    final t = _toSgd[to];
    if (f == null || t == null || t == 0) return 1.0; // unknown currency: leave unconverted instead of crashing
    return f / t;
  }

  double convert(double amount, String from, String to) => amount * rate(from, to);

  /// Converts a stored historical amount into [targetBase].
  ///
  /// [fxRate] was recorded on the day, against [fxBase]. If the user's base
  /// currency is still [fxBase] this is exact. If they changed base
  /// currency since, the amount is first put into [fxBase] with the
  /// recorded rate, then moved to [targetBase] at today's rate - the
  /// original-currency leg stays historically accurate, only the
  /// base-to-base leg uses today's rate.
  double toBaseHistorical({
    required double amount,
    required double fxRate,
    required String fxBase,
    required String targetBase,
  }) {
    final inFxBase = amount * fxRate;
    if (fxBase == targetBase) return inFxBase;
    return inFxBase * rate(fxBase, targetBase);
  }
}
