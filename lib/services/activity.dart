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
      ),
  ];
  list.sort((a, b) {
    final c = b.date.compareTo(a.date);
    return c != 0 ? c : b.createdAt.compareTo(a.createdAt);
  });
  return list;
}
