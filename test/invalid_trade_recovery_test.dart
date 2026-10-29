import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/models/trade.dart';
import 'package:huatlui/services/activity.dart';
import 'package:huatlui/services/portfolio_service.dart';
import 'package:huatlui/services/fx_service.dart';

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
  test('exact CSV precision: 5000.00003 closes Moo Moo, later CMC buyback valid', () {
    Trade trade(String id, String account, TradeType type, DateTime date,
        double quantity) => Trade(
      id: id, accountId: account, symbol: 'F9D.SI', type: type,
      tradeDate: date, createdAt: date,
      quantity: quantity, price: 2.0, currency: 'SGD', fxBase: 'SGD',
    );
    final trades = [
      trade('moomoo-buy1', 'moomoo', TradeType.buy, DateTime(2025, 11, 7), 3000),
      trade('moomoo-buy2', 'moomoo', TradeType.buy, DateTime(2025, 11, 21), 2000),
      trade('moomoo-close', 'moomoo', TradeType.sell, DateTime(2026, 2, 3), 5000.00003),
      trade('cmc-rebuy', 'cmc', TradeType.buy, DateTime(2026, 2, 11), 3000),
    ];
    expect(firstOversellIssue(trades), isNull);
    expect(tradesAreConsistent(trades), isTrue);
    final positions = PortfolioService(fx: FxService(), baseCurrency: 'SGD')
        .positions(trades: trades, dividends: [], holdings: []);
    final oldPosition = positions.singleWhere((p) => p.accountId == 'moomoo');
    final newPosition = positions.singleWhere((p) => p.accountId == 'cmc');
    expect(oldPosition.quantity, 0);
    expect(oldPosition.costLocal, 0);
    expect(newPosition.quantity, 3000);
  });

  test('material oversell is still rejected', () {
    final buy = txn('buy', TradeType.buy, 1, 5000);
    final sell = txn('sell', TradeType.sell, 2, 5000.1);
    expect(firstOversellIssue([buy, sell]), isNotNull);
    expect(tradesAreConsistent([buy, sell]), isFalse);
  });


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
