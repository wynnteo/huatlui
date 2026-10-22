import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/trade.dart';

/// Sample portfolio so every screen has something to show: three
/// currencies (SGD / USD / MYR), two brokers, a partial sell, dividends
/// with withholding tax, and some target weights (including a deliberately
/// off-target one so the concentration warnings light up).
class DemoData {
  final List<Account> accounts;
  final List<HoldingRecord> holdings;
  final List<Trade> trades;
  final List<Dividend> dividends;

  const DemoData(this.accounts, this.holdings, this.trades, this.dividends);

  static DemoData build() {
    const uuid = Uuid();
    final now = DateTime.now();
    String id() => uuid.v4();

    final tiger = Account(id: id(), name: 'Tiger Brokers', createdAt: now);
    final ibkr = Account(id: id(), name: 'Interactive Brokers', createdAt: now);

    HoldingRecord h(Account a, String symbol, String name, AssetClass cls, String ccy, double price, {double? target}) =>
        HoldingRecord(
          id: id(),
          accountId: a.id,
          symbol: symbol,
          name: name,
          assetClass: cls,
          currency: ccy,
          currentPrice: price,
          priceUpdatedAt: now,
          targetPct: target,
        );

    final holdings = [
      h(tiger, 'AAPL', 'Apple Inc.', AssetClass.stock, 'USD', 215.0, target: 20),
      h(tiger, 'D05.SI', 'DBS Group', AssetClass.stock, 'SGD', 38.4, target: 25),
      h(ibkr, 'VWRA.L', 'Vanguard FTSE All-World', AssetClass.etf, 'USD', 130.0, target: 40),
      h(ibkr, '1155.KL', 'Maybank', AssetClass.stock, 'MYR', 10.1, target: 15),
    ];

    Trade t(Account a, String symbol, TradeType type, DateTime date, double qty, double price, String ccy, double fx,
            {double fee = 0}) =>
        Trade(
          id: id(),
          accountId: a.id,
          symbol: symbol,
          type: type,
          tradeDate: date,
          quantity: qty,
          price: price,
          currency: ccy,
          fxRate: fx,
          fxBase: 'SGD',
          commission: fee,
          createdAt: date,
        );

    // fx values below are SGD per 1 unit of the trade currency on that date.
    // Recorded against SGD on purpose: if the user later switches the base
    // currency, FxService converts the history instead of misreading it.
    final trades = [
      t(tiger, 'AAPL', TradeType.buy, DateTime(2025, 3, 10), 10, 170, 'USD', 1.34, fee: 1.0),
      t(tiger, 'AAPL', TradeType.buy, DateTime(2025, 9, 2), 5, 190, 'USD', 1.29, fee: 1.0),
      t(tiger, 'D05.SI', TradeType.buy, DateTime(2025, 2, 3), 200, 33.5, 'SGD', 1.0, fee: 5),
      t(tiger, 'D05.SI', TradeType.sell, DateTime(2026, 1, 15), 50, 38.0, 'SGD', 1.0, fee: 3),
      t(ibkr, 'VWRA.L', TradeType.buy, DateTime(2025, 4, 8), 20, 118, 'USD', 1.33, fee: 1.5),
      t(ibkr, '1155.KL', TradeType.buy, DateTime(2025, 5, 20), 500, 9.4, 'MYR', 0.29, fee: 8),
    ];

    Dividend d(Account a, String symbol, String ccy, double fx, double gross, double tax, DateTime date) => Dividend(
          id: id(),
          accountId: a.id,
          symbol: symbol,
          currency: ccy,
          fxRate: fx,
          fxBase: 'SGD',
          grossAmount: gross,
          withholdingTax: tax,
          paymentDate: date,
          createdAt: date,
        );

    final dividends = [
      d(tiger, 'D05.SI', 'SGD', 1.0, 150, 0, DateTime(2025, 8, 12)),
      d(tiger, 'AAPL', 'USD', 1.30, 12, 3.6, DateTime(2025, 11, 14)),
      d(ibkr, '1155.KL', 'MYR', 0.30, 90, 0, DateTime(2025, 9, 30)),
    ];

    return DemoData([tiger, ibkr], holdings, trades, dividends);
  }
}
