import '../models/holding_record.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/trade.dart';

enum ActivityKind { buy, sell, dividend }

/// One line in the combined transactions feed (trades + dividends).
class Activity {
  final String id;
  final ActivityKind kind;
  final DateTime date;
  final DateTime createdAt;
  final String accountId;
  final String symbol;
  final String currency;
  final double amount; // in [currency]: buy cost, sell proceeds, or net dividend
  final double fxRate;
  final String fxBase;
  final double? quantity;
  final double? price;

  const Activity({
    required this.id,
    required this.kind,
    required this.date,
    required this.createdAt,
    required this.accountId,
    required this.symbol,
    required this.currency,
    required this.amount,
    required this.fxRate,
    required this.fxBase,
    this.quantity,
    this.price,
  });
}

List<Activity> buildActivity(List<Trade> trades, List<Dividend> dividends) {
  final list = <Activity>[
    for (final t in trades)
      Activity(
        id: t.id,
        kind: t.type == TradeType.buy ? ActivityKind.buy : ActivityKind.sell,
        date: t.tradeDate,
        createdAt: t.createdAt,
        accountId: t.accountId,
        symbol: t.symbol,
        currency: t.currency,
        amount: t.netAmount,
        fxRate: t.fxRate,
        fxBase: t.fxBase,
        quantity: t.quantity,
        price: t.price,
      ),
    for (final d in dividends)
      Activity(
        id: d.id,
        kind: ActivityKind.dividend,
        date: d.paymentDate,
        createdAt: d.createdAt,
        accountId: d.accountId,
        symbol: d.symbol,
        currency: d.currency,
        amount: d.netAmount,
        fxRate: d.fxRate,
        fxBase: d.fxBase,
      ),
  ];
  list.sort((a, b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
  });
  return list;
}

/// Consistent transaction ordering for both validation and cost accounting.
/// Buys precede sells on the same day because trade records have no execution time.
int compareTradesForAccounting(Trade a, Trade b) {
  final date = a.tradeDate.compareTo(b.tradeDate);
  if (date != 0) return date;
  if (a.type != b.type) return a.type == TradeType.buy ? -1 : 1;
  final created = a.createdAt.compareTo(b.createdAt);
  return created != 0 ? created : a.id.compareTo(b.id);
}

/// First transaction that makes a holding's running quantity negative.
/// The original trade is retained for user review; no data is modified.
class OversellIssue {
  final Trade trade;
  final double available;
  const OversellIssue(this.trade, this.available);
}

OversellIssue? firstOversellIssue(List<Trade> trades) {
  final byKey = <String, List<Trade>>{};
  for (final t in trades) {
    byKey.putIfAbsent(HoldingRecord.keyOf(t.accountId, t.symbol), () => []).add(t);
  }
  for (final list in byKey.values) {
    list.sort(compareTradesForAccounting);
    var available = 0.0;
    for (final t in list) {
      if (t.type == TradeType.buy) {
        available += t.quantity;
      } else {
        if (t.quantity > available + 1e-9) return OversellIssue(t, available);
        available -= t.quantity;
      }
    }
  }
  return null;
}

/// True if, for every holding, no sale is ever larger than the units held on
/// that day (replaying the trades in date order).
bool tradesAreConsistent(List<Trade> trades) => firstOversellIssue(trades) == null;

/// An edit or delete is refused only if it makes things WORSE. Data that was
/// already off (say, an import that sold more than it bought) never blocks
/// an unrelated change.
bool changeBreaksHoldings(List<Trade> before, List<Trade> after) =>
    tradesAreConsistent(before) && !tradesAreConsistent(after);
