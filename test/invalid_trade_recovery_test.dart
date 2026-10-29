import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/models/trade.dart';
import 'package:huatlui/services/activity.dart';

Trade txn(String id, TradeType type, int day, double qty) => Trade(
  id: id,
  accountId: 'broker-1',
  symbol: 'F9D.SI',
  type: type,
  tradeDate: DateTime.utc(2026, 10, day),
  createdAt: DateTime.utc(2026, 10, day),
  quantity: qty,
  price: 2.0,
  currency: 'SGD',
  fxBase: 'SGD',
);

void main() {
  test('detects oversell with actual available shares and transaction', () {
    final buys = txn('buy-1', TradeType.buy, 1, 100);
    final badSell = txn('sell-1', TradeType.sell, 2, 150);
    final issue = firstOversellIssue([badSell, buys]);
    expect(issue, isNotNull);
    expect(issue!.trade.id, 'sell-1');
    expect(issue.available, 100);
    expect(tradesAreConsistent([badSell, buys]), isFalse);
  });

  test('same-day buy before sell remains valid', () {
    final buy = txn('buy', TradeType.buy, 1, 100);
    final sell = txn('sell', TradeType.sell, 1, 90);
    expect(firstOversellIssue([sell, buy]), isNull);
    expect(tradesAreConsistent([sell, buy]), isTrue);
  });

  test('diagnosing history never mutates original trade order', () {
    final buy = txn('buy', TradeType.buy, 1, 100);
    final sell = txn('sell', TradeType.sell, 2, 120);
    final trades = [sell, buy];
    firstOversellIssue(trades);
    expect(trades.first.id, 'sell');
  });

  test('repairing invalid sell returns history to normal', () {
    final buy = txn('buy', TradeType.buy, 1, 100);
    final sell = txn('sell', TradeType.sell, 2, 120);
    expect(tradesAreConsistent([buy, sell]), isFalse);
    expect(tradesAreConsistent([buy, txn('corrected', TradeType.sell, 2, 80)]), isTrue);
  });
}
