import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/models/holding_record.dart';
import 'package:huatlui/models/price_point.dart';
import 'package:huatlui/models/trade.dart';
import 'package:huatlui/services/portfolio_repository.dart';
import 'package:huatlui/services/price_providers.dart';
import 'package:huatlui/services/price_service.dart';

class FakeRepository extends PortfolioRepository {
  List<HoldingRecord> saved = [];
  @override
  Future<void> applyPriceRefresh(List<HoldingRecord> updated, Map<String, List<PricePoint>> history, {int? expectedGeneration}) async {
    saved = updated;
    for (final h in updated) {
      holdings.removeWhere((old) => old.key == h.key);
      holdings.add(h);
    }
    notifyListeners();
  }
}

class FakeProvider implements PriceProvider {
  final Map<String, PriceQuote?> quotes;
  int requests = 0;
  FakeProvider(this.quotes);
  @override
  Future<PriceQuote?> fetch(PriceRequest request) async {
    requests++;
    return quotes[request.symbol];
  }
}

HoldingRecord holding(String account, String currency, DateTime? updated,
    {AssetClass cls = AssetClass.stock, double price = 10}) =>
    HoldingRecord(
      id: '$account-$currency',
      accountId: account,
      symbol: 'SAME',
      name: 'Holding',
      currency: currency,
      assetClass: cls,
      currentPrice: price,
      priceUpdatedAt: updated,
    );

Trade buy(String account, String currency) => Trade(
  id: account,
  accountId: account,
  symbol: 'SAME',
  type: TradeType.buy,
  tradeDate: DateTime(2026, 1, 1),
  createdAt: DateTime(2026, 1, 1),
  quantity: 1,
  price: 10,
  currency: currency,
  fxBase: currency,
);

void main() {
  test('one stale holding triggers refresh even if another is fresh', () {
    final repo = FakeRepository();
    final now = DateTime(2026, 10, 29, 12);
    repo.trades = [buy('old', 'SGD'), buy('new', 'SGD')];
    repo.holdings = [
      holding('old', 'SGD', now.subtract(const Duration(hours: 2))),
      holding('new', 'SGD', now.subtract(const Duration(minutes: 1))),
    ];
    final controller = PriceController(repo: repo);
    expect(controller.hasStalePrices(now: now), isTrue);
    expect(controller.lastUpdated, now.subtract(const Duration(hours: 2)));
  });

  test('unknown quote currency is rejected, old price preserved', () async {
    final repo = FakeRepository();
    repo.trades = [buy('a', 'SGD')];
    repo.holdings = [holding('a', 'SGD', null, price: 12)];
    final provider = FakeProvider({
      'SAME': const PriceQuote(symbol: 'SAME', price: 500),
    });
    final controller = PriceController(repo: repo, stocks: provider);
    final result = await controller.refreshAll();
    expect(result!.failed, 1);
    expect(repo.saved, isEmpty);
    expect(repo.holdings.single.currentPrice, 12);
  });

  test('mismatched quote currency is rejected', () async {
    final repo = FakeRepository();
    repo.trades = [buy('a', 'SGD')];
    repo.holdings = [holding('a', 'SGD', null, price: 12)];
    final provider = FakeProvider({
      'SAME': const PriceQuote(symbol: 'SAME', price: 500, currency: 'USD'),
    });
    final controller = PriceController(repo: repo, stocks: provider);
    final result = await controller.refreshAll();
    expect(result!.failed, 1);
    expect(repo.holdings.single.currentPrice, 12);
  });

  test('ambiguous ticker across currencies skips both holdings', () async {
    final repo = FakeRepository();
    repo.trades = [buy('sg', 'SGD'), buy('us', 'USD')];
    repo.holdings = [holding('sg', 'SGD', null), holding('us', 'USD', null)];
    final provider = FakeProvider({
      'SAME': const PriceQuote(symbol: 'SAME', price: 99, currency: 'SGD'),
    });
    final controller = PriceController(repo: repo, stocks: provider);
    final result = await controller.refreshAll();
    expect(result!.failed, 1);
    expect(provider.requests, 0);
    expect(repo.saved, isEmpty);
  });

  test('one valid quote safely updates identical holdings at two brokers', () async {
    final repo = FakeRepository();
    repo.trades = [buy('a', 'SGD'), buy('b', 'SGD')];
    repo.holdings = [holding('a', 'SGD', null), holding('b', 'SGD', null)];
    final provider = FakeProvider({
      'SAME': const PriceQuote(symbol: 'SAME', price: 16, currency: 'SGD'),
    });
    final controller = PriceController(repo: repo, stocks: provider);
    final result = await controller.refreshAll();
    expect(result!.updated, 1);
    expect(provider.requests, 1);
    expect(repo.saved.length, 2);
    expect(repo.saved.every((h) => h.currentPrice == 16), isTrue);
  });

  test('failed fetch retains old price and retry eligibility', () async {
    final repo = FakeRepository();
    repo.trades = [buy('a', 'SGD')];
    repo.holdings = [holding('a', 'SGD', null, price: 11)];
    final controller = PriceController(repo: repo, stocks: FakeProvider({}));
    final result = await controller.refreshAll();
    expect(result!.failed, 1);
    expect(repo.holdings.single.currentPrice, 11);
    expect(controller.hasStalePrices(), isTrue);
  });
}
