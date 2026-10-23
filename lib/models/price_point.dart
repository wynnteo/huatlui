/// One closing price on one day, in the instrument's own currency.
class PricePoint {
  final DateTime date; // midnight, local
  final double price;
  const PricePoint(this.date, this.price);

  List<num> toJson() => [date.millisecondsSinceEpoch, price];

  factory PricePoint.fromJson(dynamic e) {
    final l = e as List;
    return PricePoint(DateTime.fromMillisecondsSinceEpoch((l[0] as num).toInt()), (l[1] as num).toDouble());
  }
}

/// What a price provider hands back for one symbol.
class PriceQuote {
  final String symbol;
  final double price; // latest, in [currency]
  final String? currency; // null when the source doesn't say
  final DateTime? asOf;
  final List<PricePoint> history; // may be empty (unit trusts have none)

  const PriceQuote({
    required this.symbol,
    required this.price,
    this.currency,
    this.asOf,
    this.history = const [],
  });
}
