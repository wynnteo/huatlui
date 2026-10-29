import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/dividend.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/services/holdings_view.dart';
import 'package:huatlui/services/portfolio_service.dart';

Dividend dividend(String broker, String symbol, DateTime date, double gross, double tax) =>
    Dividend(
      id: '$broker-$symbol-${date.toIso8601String()}',
      accountId: broker, symbol: symbol,
      currency: 'SGD', fxBase: 'SGD',
      grossAmount: gross, withholdingTax: tax,
      paymentDate: date, createdAt: date,
    );

Position holding(String account, String symbol, AssetClass cls, double value,
    double profit, double percentage) => Position(
  accountId: account, symbol: symbol, name: symbol,
  assetClass: cls, currency: 'SGD',
  quantity: 100, costLocal: 1000, costBase: 1000,
  currentPrice: 10, marketValueLocal: value, marketValueBase: value,
  realizedBase: 0, dividendsBase: 0, totalBoughtBase: 1000,
);

void main() {
  test('YTD net dividends filter by payment year, broker and symbol', () {
    final values = [
      dividend('a', 'F9D.SI', DateTime(2026, 2, 1), 100, 10),
      dividend('a', 'f9d.si', DateTime(2026, 10, 1), 20, 0),
      dividend('a', 'F9D.SI', DateTime(2025, 12, 31), 300, 0),
      dividend('b', 'F9D.SI', DateTime(2026, 10, 1), 500, 0),
      dividend('a', 'A17U.SI', DateTime(2026, 10, 1), 600, 0),
      dividend('a', 'F9D.SI', DateTime(2027, 1, 1), 1000, 0),
    ];
    expect(netDividendsForYear(
        dividends: values, accountId: 'a', symbol: 'F9D.SI', year: 2026), 110);
    expect(netDividendsForYear(
        dividends: values, accountId: 'a', symbol: 'F9D.SI', year: 2024), 0);
  });

  test('sorting and filtering do not alter underlying list', () {
    final positions = [
      holding('a', 'Z.SI', AssetClass.stock, 90, -20, -10),
      holding('b', 'A.SI', AssetClass.etf, 250, 30, 4),
      holding('a', 'C.SI', AssetClass.etf, 120, 5, 2),
    ];
    final byBroker = filterAndSortHoldings(positions: positions, accountId: 'a');
    expect(byBroker.map((p) => p.symbol).toList(), ['C.SI', 'Z.SI']);
    final etfs = filterAndSortHoldings(positions: positions, assetClass: AssetClass.etf);
    expect(etfs.map((p) => p.symbol).toList(), ['A.SI', 'C.SI']);
    expect(positions.map((p) => p.symbol).toList(), ['Z.SI', 'A.SI', 'C.SI']);
    final sorted = filterAndSortHoldings(
      positions: positions, sort: HoldingSort.marketValue, descending: true);
    expect(sorted.map((p) => p.symbol).toList(), ['A.SI', 'C.SI', 'Z.SI']);
  });

  test('combined broker and asset filters', () {
    final positions = [
      holding('a', 'AA', AssetClass.stock, 100, 0, 0),
      holding('a', 'BB', AssetClass.etf, 200, 0, 0),
      holding('b', 'CC', AssetClass.etf, 300, 0, 0),
    ];
    final visible = filterAndSortHoldings(
      positions: positions, accountId: 'a', assetClass: AssetClass.etf);
    expect(visible.single.symbol, 'BB');
  });
}
