import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/dividend.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/models/holding_record.dart';
import 'package:huatlui/services/fx_service.dart';
import 'package:huatlui/services/insights_service.dart';

HoldingRecord holding(String account, String symbol, AssetClass type) =>
    HoldingRecord(
      id: '$account-$symbol',
      accountId: account,
      symbol: symbol,
      name: symbol,
      assetClass: type,
      currency: 'SGD',
      currentPrice: 1,
    );

Dividend dividend(String id, String account, String symbol, double gross,
    double tax, {String currency = 'SGD', double fxRate = 1,
    String fxBase = 'SGD', int year = 2026}) =>
    Dividend(
      id: id,
      accountId: account,
      symbol: symbol,
      currency: currency,
      fxRate: fxRate,
      fxBase: fxBase,
      grossAmount: gross,
      withholdingTax: tax,
      paymentDate: DateTime(year, 5, 15),
      createdAt: DateTime(year, 5, 15),
    );

void main() {
  final service = InsightsService(
    fx: FxService(),
    baseCurrency: 'SGD',
  );

  test('all income groups UT, stocks and REIT by asset class, net of tax', () {
    final holdings = [
      holding('poems', 'FUND-A', AssetClass.unitTrust),
      holding('poems', 'FUND-B', AssetClass.unitTrust),
      holding('broker', 'DBS', AssetClass.stock),
      holding('broker', 'A17U', AssetClass.reit),
    ];
    final records = [
      dividend('1', 'poems', 'FUND-A', 180, 10),
      dividend('2', 'poems', 'FUND-B', 90, 0),
      dividend('3', 'broker', 'DBS', 100, 5),
      dividend('4', 'broker', 'A17U', 40, 0),
    ];
    final result = service.dividendsByAssetClass(records, holdings);
    final amounts = {for (final item in result) item.assetClass: item.amountBase};
    expect(amounts[AssetClass.unitTrust], 260);
    expect(amounts[AssetClass.stock], 95);
    expect(amounts[AssetClass.reit], 40);
    expect(result.first.assetClass, AssetClass.unitTrust);
    expect(result.fold<double>(0, (sum, v) => sum + v.amountBase), 395);
  });

  test('same symbol in different broker accounts uses own asset class', () {
    final holdings = [
      holding('broker-a', 'ABC', AssetClass.stock),
      holding('broker-b', 'ABC', AssetClass.unitTrust),
    ];
    final records = [
      dividend('1', 'broker-a', 'abc', 10, 0),
      dividend('2', 'broker-b', 'ABC', 20, 0),
    ];
    final sums = {
      for (final item in service.dividendsByAssetClass(records, holdings))
        item.assetClass: item.amountBase
    };
    expect(sums[AssetClass.stock], 10);
    expect(sums[AssetClass.unitTrust], 20);
  });

  test('income with missing holding record goes to Other, not discarded', () {
    final results = service.dividendsByAssetClass(
      [dividend('a', 'legacy', 'UNKNOWN', 50, 0)], [],
    );
    expect(results.single.assetClass, AssetClass.other);
    expect(results.single.amountBase, 50);
  });

  test('income uses historical FX and not current quoted FX', () {
    final holdings = [holding('broker', 'USD', AssetClass.etf)];
    final income = [dividend('a', 'broker', 'USD', 20, 2,
        currency: 'USD', fxRate: 1.4, fxBase: 'SGD')];
    final result = service.dividendsByAssetClass(income, holdings);
    expect(result.single.amountBase, closeTo(25.2, 0.000001));
  });

  test('empty income returns no categories', () {
    expect(service.dividendsByAssetClass([], []), isEmpty);
  });
}
