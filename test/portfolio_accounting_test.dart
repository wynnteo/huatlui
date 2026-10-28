import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/models/trade.dart';
import 'package:huatlui/services/activity.dart';
import 'package:huatlui/services/fx_service.dart';
import 'package:huatlui/services/portfolio_service.dart';

Trade trade(String id, TradeType type, int day, double quantity, double price,
    {int createdHour = 12, double fee = 0}) {
  return Trade(
    id: id,
    accountId: 'broker',
    symbol: 'TEST.SI',
    type: type,
    tradeDate: DateTime(2026, 10, day),
    createdAt: DateTime(2026, 10, day, createdHour),
    quantity: quantity,
    price: price,
    currency: 'SGD',
    fxBase: 'SGD',
    commission: fee,
  );
}

void main() {
  final svc = PortfolioService(fx: FxService(), baseCurrency: 'SGD');

  test('weighted average cost, fees and partial sale are calculated correctly', () {
    final trades = [
      trade('b1', TradeType.buy, 1, 100, 2, fee: 2),
      trade('b2', TradeType.buy, 2, 100, 4, fee: 2),
      trade('s1', TradeType.sell, 3, 50, 5, fee: 1),
    ];
    final p = svc.positions(trades: trades, dividends: [], holdings: []).single;
    expect(p.quantity, 150);
    expect(p.costLocal, closeTo(453, 0.000001));
    expect(p.avgCostLocal, closeTo(3.02, 0.000001));
    expect(p.realizedLocal, closeTo(98, 0.000001));
  });

  test('buy and sell on same date share validator and accounting order', () {
    final trades = [
      trade('sell', TradeType.sell, 1, 5, 3, createdHour: 9),
      trade('buy', TradeType.buy, 1, 10, 2, createdHour: 15),
    ];
    expect(tradesAreConsistent(trades), isTrue);
    final p = svc.positions(trades: trades, dividends: [], holdings: []).single;
    expect(p.quantity, 5);
    expect(p.realizedLocal, closeTo(5, 0.000001));
  });

  test('oversells fail explicitly rather than silently discarding shares', () {
    final trades = [
      trade('b', TradeType.buy, 1, 3, 2),
      trade('s', TradeType.sell, 2, 5, 4),
    ];
    expect(tradesAreConsistent(trades), isFalse);
    expect(() => svc.positions(trades: trades, dividends: [], holdings: []),
        throwsStateError);
  });
}
