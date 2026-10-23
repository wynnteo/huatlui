import 'package:uuid/uuid.dart';
import '../models/account.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/trade.dart';
import 'fx_service.dart';
import 'parse_utils.dart';

/// Minimal RFC-4180 CSV reader (quoted fields, escaped quotes, commas and
/// newlines inside quotes, BOM, CRLF). Written by hand so the importer has
/// no dependency whose API can change between versions.
List<List<String>> parseCsv(String input) {
  if (input.startsWith('\uFEFF')) input = input.substring(1);
  final rows = <List<String>>[];
  var row = <String>[];
  final field = StringBuffer();
  var inQuotes = false;
  var i = 0;
  while (i < input.length) {
    final ch = input[i];
    if (inQuotes) {
      if (ch == '"') {
        if (i + 1 < input.length && input[i + 1] == '"') {
          field.write('"');
          i += 2;
          continue;
        }
        inQuotes = false;
        i++;
        continue;
      }
      field.write(ch);
      i++;
      continue;
    }
    if (ch == '"') {
      inQuotes = true;
    } else if (ch == ',') {
      row.add(field.toString());
      field.clear();
    } else if (ch == '\n') {
      row.add(field.toString());
      field.clear();
      rows.add(row);
      row = <String>[];
    } else if (ch != '\r') {
      field.write(ch);
    }
    i++;
  }
  if (field.isNotEmpty || row.isNotEmpty) {
    row.add(field.toString());
    rows.add(row);
  }
  return rows;
}

class ImportError {
  final int row; // 1 = the header row
  final String message;
  const ImportError(this.row, this.message);
}

class ImportPlan {
  final List<Account> newAccounts;
  final List<HoldingRecord> holdingUpserts;
  final List<Trade> trades;
  final List<Dividend> dividends;
  final int skippedDuplicates;
  final List<ImportError> errors;

  const ImportPlan({
    this.newAccounts = const [],
    this.holdingUpserts = const [],
    this.trades = const [],
    this.dividends = const [],
    this.skippedDuplicates = 0,
    this.errors = const [],
  });

  bool get isEmpty => trades.isEmpty && dividends.isEmpty && holdingUpserts.isEmpty;
}

class _Draft {
  final String accountId;
  final String symbol;
  final String currency;
  String? name;
  AssetClass? assetClass;
  double? target;
  double? priceOverride;
  DateTime? overrideDate;
  double? lastTradePrice;
  DateTime? lastTradeDate;
  _Draft(this.accountId, this.symbol, this.currency);
}

class CsvImporter {
  /// The file format is the same one the web app exports (Transactions ->
  /// Export to CSV), so a file can move between the two apps in either
  /// direction. One row per event. Required columns: Date, Type, Symbol,
  /// Currency. Column order does not matter and header case/spaces are
  /// ignored. The backup extras that Export adds (FX Rate, FX Base,
  /// Withholding Tax, Target %, Current Price, Asset Type) are read back when
  /// present. "Dividend Amount" is the amount actually received; if a
  /// Withholding Tax is given, gross = amount + tax.
  static const templateCsv = 'Date,Type,Symbol,Product Name,Category,Broker,Currency,Quantity,Price,Commission,Dividend Amount,Total Value,Notes\n'
      '2026-10-20,BUY,K71U.SI,Keppel Reit,Stocks,CMC Invest,SGD,1000,0.795,0.32,,795.32,\n'
      '2026-10-18,BUY,VWRA.L,VANGUARD FTSE ALL-WORLD UCITS ETF USD ACCUMULATION,ETF,FSMOne,USD,6.4577,191.543,0,,1236.93,\n'
      '2026-10-15,SELL,558.SI,UMS,Stocks,CMC Invest,SGD,500,2.4,0.5,,1199.5,\n'
      '2026-10-18,DIVIDEND,SG9999007991:SGD,Schroder Asian Income A DIS SGD,Unit Trusts,HSBC,SGD,,,,60.68,60.68,\n';

  static const _aliases = <String, String>{
    'date': 'date', 'trade_date': 'date', 'tradedate': 'date',
    'type': 'type', 'action': 'type',
    'account': 'account', 'broker': 'account',
    'symbol': 'symbol', 'ticker': 'symbol', 'code': 'symbol',
    'name': 'name', 'product_name': 'name', 'productname': 'name',
    'asset_class': 'asset_class', 'assetclass': 'asset_class', 'category': 'asset_class', 'class': 'asset_class',
    'currency': 'currency', 'ccy': 'currency',
    'quantity': 'quantity', 'qty': 'quantity', 'units': 'quantity', 'shares': 'quantity',
    'price': 'price', 'trade_price': 'price',
    'fees': 'fees', 'fee': 'fees', 'commission': 'fees',
    'amount': 'amount', 'dividend_amount': 'amount', 'dividendamount': 'amount', 'dividend': 'amount',
    'total_value': 'total_value', 'totalvalue': 'total_value',
    'fx_base': 'fx_base', 'fxbase': 'fx_base',
    'asset_type': 'asset_type', 'assettype': 'asset_type',
    'target_%': 'target_pct',
    'tax': 'tax', 'withholding_tax': 'tax', 'withholdingtax': 'tax',
    'fx_rate': 'fx_rate', 'fxrate': 'fx_rate', 'fx': 'fx_rate',
    'current_price': 'current_price', 'currentprice': 'current_price',
    'target_pct': 'target_pct', 'target': 'target_pct',
    'notes': 'notes', 'note': 'notes', 'remarks': 'notes',
  };

  static String _normHeader(String h) => h.trim().toLowerCase().replaceAll(RegExp(r'[\s\-]+'), '_');

  static String? _type(String v) {
    switch (v.trim().toLowerCase()) {
      case 'buy':
      case 'b':
      case 'purchase':
        return 'buy';
      case 'sell':
      case 's':
        return 'sell';
      case 'dividend':
      case 'dividends':
      case 'div':
        return 'dividend';
    }
    return null;
  }

  static AssetClass? _assetClass(String v) {
    final k = v.trim().toLowerCase().replaceAll(RegExp(r'[\s_\-]+'), '');
    if (k.isEmpty) return null;
    switch (k) {
      case 'stock':
      case 'stocks':
      case 'equity':
      case 'equities':
        return AssetClass.stock;
      case 'etf':
      case 'etfs':
        return AssetClass.etf;
      case 'unittrust':
      case 'unittrusts':
      case 'fund':
      case 'funds':
      case 'mutualfund':
        return AssetClass.unitTrust;
      case 'reit':
      case 'reits':
        return AssetClass.reit;
      case 'bond':
      case 'bonds':
        return AssetClass.bond;
      case 'crypto':
      case 'cryptocurrency':
      case 'cryptocurrencies':
        return AssetClass.crypto;
      case 'cash':
        return AssetClass.cash;
    }
    return AssetClass.other;
  }

  static ImportPlan plan({
    required String csv,
    required List<Account> existingAccounts,
    required List<HoldingRecord> existingHoldings,
    required List<Trade> existingTrades,
    required List<Dividend> existingDividends,
    required String baseCurrency,
    required FxService fx,
  }) {
    const uuid = Uuid();
    final all = parseCsv(csv);
    var h = 0;
    while (h < all.length && all[h].every((c) => c.trim().isEmpty)) {
      h++;
    }
    if (h >= all.length) {
      return const ImportPlan(errors: [ImportError(1, 'The file is empty.')]);
    }

    final col = <String, int>{};
    for (var i = 0; i < all[h].length; i++) {
      final key = _aliases[_normHeader(all[h][i])];
      if (key != null) col.putIfAbsent(key, () => i);
    }
    final missing = ['date', 'type', 'symbol', 'currency'].where((c) => !col.containsKey(c)).toList();
    if (missing.isNotEmpty) {
      return ImportPlan(errors: [ImportError(h + 1, 'Missing required column(s): ${missing.join(', ')}')]);
    }

    String cell(List<String> row, String key) {
      final i = col[key];
      if (i == null || i >= row.length) return '';
      return row[i].trim();
    }

    final now = DateTime.now();
    var seq = 0;
    DateTime stamp() => now.add(Duration(milliseconds: seq++));

    final accountsByName = <String, Account>{for (final a in existingAccounts) a.name.trim().toLowerCase(): a};
    final newAccounts = <Account>[];
    final holdingsByKey = <String, HoldingRecord>{for (final x in existingHoldings) x.key: x};
    final drafts = <String, _Draft>{};

    String dayKey(DateTime d) => '${d.year}-${d.month}-${d.day}';
    final tradeKeys = <String>{
      for (final t in existingTrades)
        '${t.accountId}|${t.symbol.toUpperCase()}|${t.type.name}|${dayKey(t.tradeDate)}|${t.quantity.toStringAsFixed(6)}|${t.price.toStringAsFixed(6)}'
    };
    // A dividend can legitimately arrive as the gross amount (older files) or
    // the net amount received (this export format), so match on either.
    final divKeys = <String>{
      for (final d in existingDividends) ...[
        '${d.accountId}|${d.symbol.toUpperCase()}|${dayKey(d.paymentDate)}|${d.grossAmount.toStringAsFixed(6)}',
        '${d.accountId}|${d.symbol.toUpperCase()}|${dayKey(d.paymentDate)}|${d.netAmount.toStringAsFixed(6)}',
      ]
    };

    final errors = <ImportError>[];
    final trades = <Trade>[];
    final dividends = <Dividend>[];
    var skipped = 0;

    for (var r = h + 1; r < all.length; r++) {
      final row = all[r];
      if (row.every((c) => c.trim().isEmpty)) continue;
      final line = r + 1;
      void bad(String m) => errors.add(ImportError(line, m));

      final type = _type(cell(row, 'type'));
      if (type == null) {
        bad('type must be BUY, SELL or DIVIDEND');
        continue;
      }
      final date = parseDateLoose(cell(row, 'date'));
      if (date == null) {
        bad('date is missing or not understood (use yyyy-MM-dd or dd/MM/yyyy)');
        continue;
      }
      final symbol = cell(row, 'symbol').toUpperCase();
      if (symbol.isEmpty) {
        bad('symbol is empty');
        continue;
      }
      final currency = cell(row, 'currency').toUpperCase();
      if (currency.isEmpty) {
        bad('currency is empty');
        continue;
      }

      double fxRate;
      var fxBaseUsed = baseCurrency;
      final fxRaw = cell(row, 'fx_rate');
      if (fxRaw.isEmpty) {
        fxRate = fx.rate(currency, baseCurrency);
      } else {
        final v = parseNumber(fxRaw);
        if (v == null || v <= 0) {
          bad('fx_rate must be a positive number');
          continue;
        }
        fxRate = v;
        final fb = cell(row, 'fx_base').toUpperCase();
        if (fb.isNotEmpty) fxBaseUsed = fb; // the rate is against the base it was recorded in
      }

      double qty = 0, price = 0, fees = 0, amount = 0, tax = 0;
      if (type == 'dividend') {
        final a = parseNumber(cell(row, 'amount'));
        if (a == null || a <= 0) {
          bad('Dividend Amount must be a positive number for a dividend');
          continue;
        }
        amount = a;
        final taxRaw = cell(row, 'tax');
        if (taxRaw.isNotEmpty) {
          final tv = parseNumber(taxRaw);
          if (tv == null || tv < 0) {
            bad('tax must be a number');
            continue;
          }
          tax = tv;
        }
      } else {
        final q = parseNumber(cell(row, 'quantity'));
        if (q == null || q <= 0) {
          bad('quantity must be a positive number');
          continue;
        }
        final feeRaw = cell(row, 'fees');
        if (feeRaw.isNotEmpty) {
          final fv = parseNumber(feeRaw);
          if (fv == null || fv < 0) {
            bad('commission must be a number');
            continue;
          }
          fees = fv;
        }
        var p = parseNumber(cell(row, 'price'));
        if (p == null) {
          // Some exports only carry Total Value: work the unit price back from it.
          final total = parseNumber(cell(row, 'total_value'));
          if (total != null && total > 0) p = (type == 'buy' ? total - fees : total + fees) / q;
        }
        if (p == null || p < 0) {
          bad('price must be a number');
          continue;
        }
        qty = q;
        price = p;
      }

      final accName = cell(row, 'account').isEmpty ? 'Default' : cell(row, 'account');
      final accKey = accName.toLowerCase();
      Account? acc = accountsByName[accKey];

      if (acc != null) {
        final hKey = HoldingRecord.keyOf(acc.id, symbol);
        final knownCcy = holdingsByKey[hKey]?.currency ?? drafts[hKey]?.currency;
        if (knownCcy != null && knownCcy != currency) {
          bad('$symbol is already held in $knownCcy in "${acc.name}", not $currency');
          continue;
        }
        final dupKey = type == 'dividend'
            ? '${acc.id}|$symbol|${dayKey(date)}|${amount.toStringAsFixed(6)}'
            : '${acc.id}|$symbol|$type|${dayKey(date)}|${qty.toStringAsFixed(6)}|${price.toStringAsFixed(6)}';
        final existingKeys = type == 'dividend' ? divKeys : tradeKeys;
        if (existingKeys.contains(dupKey)) {
          skipped++;
          continue;
        }
      }

      if (acc == null) {
        acc = Account(id: uuid.v4(), name: accName, createdAt: stamp());
        accountsByName[accKey] = acc;
        newAccounts.add(acc);
      }
      final accountId = acc.id;

      final note = cell(row, 'notes').isEmpty ? null : cell(row, 'notes');
      if (type == 'dividend') {
        dividends.add(Dividend(
          id: uuid.v4(),
          accountId: accountId,
          symbol: symbol,
          currency: currency,
          fxRate: fxRate,
          fxBase: fxBaseUsed,
          grossAmount: amount + tax, // amount is what was received; tax was already taken off
          withholdingTax: tax,
          paymentDate: date,
          notes: note,
          createdAt: stamp(),
        ));
      } else {
        trades.add(Trade(
          id: uuid.v4(),
          accountId: accountId,
          symbol: symbol,
          type: type == 'buy' ? TradeType.buy : TradeType.sell,
          tradeDate: date,
          quantity: qty,
          price: price,
          currency: currency,
          fxRate: fxRate,
          fxBase: fxBaseUsed,
          commission: fees,
          notes: note,
          createdAt: stamp(),
        ));
      }

      final key = HoldingRecord.keyOf(accountId, symbol);
      final d = drafts.putIfAbsent(key, () => _Draft(accountId, symbol, currency));
      if (d.name == null && cell(row, 'name').isNotEmpty) d.name = cell(row, 'name');
      d.assetClass ??= _assetClass(cell(row, 'asset_type')) ?? _assetClass(cell(row, 'asset_class'));
      final tg = parseNumber(cell(row, 'target_pct'));
      if (tg != null) d.target = tg;
      final cp = parseNumber(cell(row, 'current_price'));
      if (cp != null && (d.overrideDate == null || !date.isBefore(d.overrideDate!))) {
        d.priceOverride = cp;
        d.overrideDate = date;
      }
      if (type != 'dividend' && (d.lastTradeDate == null || !date.isBefore(d.lastTradeDate!))) {
        d.lastTradePrice = price;
        d.lastTradeDate = date;
      }
    }

    final upserts = <HoldingRecord>[];
    for (final entry in drafts.entries) {
      final d = entry.value;
      final existing = holdingsByKey[entry.key];
      if (existing != null) {
        if (d.priceOverride != null || d.target != null) {
          upserts.add(existing.copyWith(
            currentPrice: d.priceOverride,
            targetPct: d.target,
          ));
        }
      } else {
        upserts.add(HoldingRecord(
          id: uuid.v4(),
          accountId: d.accountId,
          symbol: d.symbol,
          name: d.name ?? d.symbol,
          assetClass: d.assetClass ?? AssetClass.stock,
          currency: d.currency,
          currentPrice: d.priceOverride ?? d.lastTradePrice ?? 0,
          targetPct: d.target,
        ));
      }
    }

    return ImportPlan(
      newAccounts: newAccounts,
      holdingUpserts: upserts,
      trades: trades,
      dividends: dividends,
      skippedDuplicates: skipped,
      errors: errors,
    );
  }
}
