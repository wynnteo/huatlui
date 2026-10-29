import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/account.dart';
import 'package:huatlui/models/dividend.dart';
import 'package:huatlui/models/enums.dart';
import 'package:huatlui/models/holding_record.dart';
import 'package:huatlui/models/price_point.dart';
import 'package:huatlui/models/trade.dart';
import 'package:huatlui/services/portfolio_backup.dart';

void main() {
  final date = DateTime.utc(2026, 10, 20);
  PortfolioBackup sample() => PortfolioBackup(
    accounts: [Account(id: 'broker1', name: 'My Broker', createdAt: date)],
    holdings: [
      HoldingRecord(id: 'holding1', accountId: 'broker1', symbol: 'ABC.SI',
        name: 'Company ABC', currency: 'SGD', currentPrice: 2.7, targetPct: 20),
    ],
    trades: [
      Trade(id: 'buy1', accountId: 'broker1', symbol: 'ABC.SI',
        type: TradeType.buy, tradeDate: date, quantity: 100, price: 2.5,
        currency: 'SGD', fxBase: 'SGD', commission: 0.42,
        otherFees: 0.1, notes: 'first lot', createdAt: date),
    ],
    dividends: [
      Dividend(id: 'div1', accountId: 'broker1', symbol: 'ABC.SI',
        currency: 'SGD', fxBase: 'SGD', grossAmount: 9,
        withholdingTax: 1, paymentDate: date, createdAt: date,
        reinvested: true),
    ],
    priceHistory: {'ABC.SI': [PricePoint(date, 2.7)]},
    baseCurrency: 'SGD', locale: 'zh', themeMode: 'dark',
  );

  test('JSON round trip preserves all portfolio details', () {
    final original = sample();
    final decoded = PortfolioBackup.decode(original.encode());
    expect(decoded.accounts.single.name, 'My Broker');
    expect(decoded.holdings.single.targetPct, 20);
    expect(decoded.trades.single.commission, 0.42);
    expect(decoded.trades.single.otherFees, 0.1);
    expect(decoded.trades.single.notes, 'first lot');
    expect(decoded.dividends.single.reinvested, isTrue);
    expect(decoded.dividends.single.withholdingTax, 1);
    expect(decoded.priceHistory['ABC.SI']!.single.price, 2.7);
    expect(decoded.locale, 'zh');
    expect(decoded.themeMode, 'dark');
  });

  test('invalid version is rejected', () {
    final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
    json['version'] = 99;
    expect(() => PortfolioBackup.decode(jsonEncode(json)), throwsFormatException);
  });

  test('duplicate transaction IDs are rejected', () {
    final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
    (json['trades'] as List).add((json['trades'] as List).first);
    expect(() => PortfolioBackup.decode(jsonEncode(json)), throwsFormatException);
  });

  test('orphan holdings and trades are rejected', () {
    final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
    (json['accounts'] as List).clear();
    expect(() => PortfolioBackup.decode(jsonEncode(json)), throwsFormatException);
  });

  test('oversell is rejected before restoring', () {
    final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
    final buy = Map<String, dynamic>.from((json['trades'] as List).first as Map);
    final sell = Map<String, dynamic>.from(buy)
      ..['id'] = 'sell1'
      ..['type'] = 'sell'
      ..['quantity'] = 200
      ..['tradeDate'] = DateTime.utc(2026, 10, 21).toIso8601String();
    (json['trades'] as List).add(sell);
    expect(() => PortfolioBackup.decode(jsonEncode(json)), throwsFormatException);
  });

  test('unsupported preference and corrupt historical price are rejected', () {
    final json = jsonDecode(sample().encode()) as Map<String, dynamic>;
    (json['preferences'] as Map)['baseCurrency'] = '???';
    expect(() => PortfolioBackup.decode(jsonEncode(json)), throwsFormatException);

    final badPrice = jsonDecode(sample().encode()) as Map<String, dynamic>;
    ((badPrice['priceHistory'] as Map)['ABC.SI'] as List)[0][1] = -1;
    expect(() => PortfolioBackup.decode(jsonEncode(badPrice)), throwsFormatException);
  });
}
