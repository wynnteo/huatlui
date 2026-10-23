import '../models/account.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/trade.dart';

/// Writes the same CSV the web app exports (and CsvImporter reads), newest
/// first:
///   Date,Type,Symbol,Product Name,Category,Broker,Currency,Quantity,Price,
///   Commission,Dividend Amount,Total Value,Notes
///
/// The first 13 columns are exactly the web app's. Six extra columns follow
/// so a file is also a complete backup you can restore on a new phone:
///   FX Rate, FX Base, Withholding Tax, Target %, Current Price, Asset Type
/// (the web app and Excel simply ignore columns they don't know).
/// "Dividend Amount" is always the amount actually received; Withholding Tax
/// is the tax already taken off, so gross = amount + tax.
///
/// Not in the file: broker type, price history (it is re-downloaded), and
/// app settings (theme, language, base currency, fund API address).
class CsvExporter {
  static const headers = [
    'Date', 'Type', 'Symbol', 'Product Name', 'Category', 'Broker', 'Currency',
    'Quantity', 'Price', 'Commission', 'Dividend Amount', 'Total Value', 'Notes',
    // extras (backup)
    'FX Rate', 'FX Base', 'Withholding Tax', 'Target %', 'Current Price', 'Asset Type',
  ];

  /// The web app's category names.
  static String categoryOf(AssetClass c) {
    switch (c) {
      case AssetClass.stock:
      case AssetClass.reit:
        return 'Stocks';
      case AssetClass.etf:
        return 'ETF';
      case AssetClass.unitTrust:
        return 'Unit Trusts';
      case AssetClass.bond:
        return 'Bond';
      case AssetClass.crypto:
        return 'Crypto';
      case AssetClass.cash:
        return 'Cash';
      case AssetClass.other:
        return 'Other';
    }
  }

  static String _date(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Up to 6 decimals, no trailing zeros, never scientific notation.
  static String _n(double v) {
    var s = v.toStringAsFixed(6);
    if (s.contains('.')) {
      s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    }
    return s;
  }

  static String _cell(String v) {
    if (v.contains(',') || v.contains('"') || v.contains('\n') || v.contains('\r')) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }

  static String build({
    required List<Trade> trades,
    required List<Dividend> dividends,
    required List<HoldingRecord> holdings,
    required List<Account> accounts,
  }) {
    final holdingByKey = {for (final h in holdings) h.key: h};
    final accountName = {for (final a in accounts) a.id: a.name};

    final rows = <_Row>[];
    for (final t in trades) {
      final h = holdingByKey[HoldingRecord.keyOf(t.accountId, t.symbol)];
      rows.add(_Row(t.tradeDate, t.createdAt, [
        _date(t.tradeDate),
        t.type == TradeType.buy ? 'BUY' : 'SELL',
        t.symbol,
        h?.name ?? t.symbol,
        categoryOf(h?.assetClass ?? AssetClass.stock),
        accountName[t.accountId] ?? '',
        t.currency,
        _n(t.quantity),
        _n(t.price),
        _n(t.fees),
        '',
        t.netAmount.toStringAsFixed(2), // buy: cost incl. fees. sell: proceeds after fees
        t.notes ?? '',
        _n(t.fxRate),
        t.fxBase,
        '',
        h?.targetPct == null ? '' : _n(h!.targetPct!),
        (h != null && h.currentPrice > 0) ? _n(h.currentPrice) : '',
        (h?.assetClass ?? AssetClass.stock).name,
      ]));
    }
    for (final d in dividends) {
      final h = holdingByKey[HoldingRecord.keyOf(d.accountId, d.symbol)];
      rows.add(_Row(d.paymentDate, d.createdAt, [
        _date(d.paymentDate),
        'DIVIDEND',
        d.symbol,
        h?.name ?? d.symbol,
        categoryOf(h?.assetClass ?? AssetClass.stock),
        accountName[d.accountId] ?? '',
        d.currency,
        '',
        '',
        '',
        _n(d.netAmount),
        d.netAmount.toStringAsFixed(2),
        d.notes ?? '',
        _n(d.fxRate),
        d.fxBase,
        d.withholdingTax > 0 ? _n(d.withholdingTax) : '',
        h?.targetPct == null ? '' : _n(h!.targetPct!),
        (h != null && h.currentPrice > 0) ? _n(h.currentPrice) : '',
        (h?.assetClass ?? AssetClass.stock).name,
      ]));
    }

    rows.sort((a, b) {
      final c = b.date.compareTo(a.date);
      return c != 0 ? c : b.created.compareTo(a.created);
    });

    final out = StringBuffer(headers.join(','))..write('\n');
    for (final r in rows) {
      out
        ..write(r.cells.map(_cell).join(','))
        ..write('\n');
    }
    return out.toString();
  }
}

class _Row {
  final DateTime date;
  final DateTime created;
  final List<String> cells;
  const _Row(this.date, this.created, this.cells);
}
