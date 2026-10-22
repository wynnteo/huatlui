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
  /// One row per event. Required columns: date, type, symbol, currency.
  static const templateCsv = 'date,type,account,symbol,name,asset_class,currency,quantity,price,fees,amount,tax,fx_rate,current_price,target_pct,notes\n'
      '2025-02-03,BUY,Tiger Brokers,D05.SI,DBS Group,stock,SGD,200,33.50,5.00,,,1,38.40,25,\n'
      '2025-03-10,BUY,Tiger Brokers,AAPL,Apple Inc.,stock,USD,10,170.00,1.00,,,1.34,215.00,20,First buy\n'
      '2025-09-02,BUY,Tiger Brokers,AAPL,,,USD,5,190.00,1.00,,,1.29,,,\n'
      '2026-01-15,SELL,Tiger Brokers,D05.SI,,,SGD,50,38.00,3.00,,,1,,,\n'
      '2025-11-14,DIVIDEND,Tiger Brokers,AAPL,,,USD,,,,12.00,3.60,1.30,,,\n'
      '2025-04-08,BUY,Interactive Brokers,VWRA.L,Vanguard FTSE All-World,etf,USD,20,118.00,1.50,,,1.33,130.00,40,\n'
      '2025-05-20,BUY,Interactive Brokers,1155.KL,Maybank,stock,MYR,500,9.40,8.00,,,0.29,10.10,15,\n';

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
    'amount': 'amount', 'dividend_amount': 'amount', 'dividend': 'amount',
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
    final divKeys = <String>{
      for (final d in existingDividends)
        '${d.accountId}|${d.symbol.toUpperCase()}|${dayKey(d.paymentDate)}|${d.grossAmount.toStringAsFixed(6)}'
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
      }

      double qty = 0, price = 0, fees = 0, amount = 0, tax = 0;
      if (type == 'dividend') {
        final a = parseNumber(cell(row, 'amount'));
        if (a == null || a <= 0) {
          bad('amount must be a positive number for a dividend');
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
        final p = parseNumber(cell(row, 'price'));
        if (q == null || q <= 0) {
          bad('quantity must be a positive number');
          continue;
        }
        if (p == null || p < 0) {
          bad('price must be a number');
          continue;
        }
        qty = q;
        price = p;
        final feeRaw = cell(row, 'fees');
        if (feeRaw.isNotEmpty) {
          final fv = parseNumber(feeRaw);
          if (fv == null || fv < 0) {
            bad('fees must be a number');
            continue;
          }
          fees = fv;
        }
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
          fxBase: baseCurrency,
          grossAmount: amount,
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
          fxBase: baseCurrency,
          commission: fees,
          notes: note,
          createdAt: stamp(),
        ));
      }

      final key = HoldingRecord.keyOf(accountId, symbol);
      final d = drafts.putIfAbsent(key, () => _Draft(accountId, symbol, currency));
      if (d.name == null && cell(row, 'name').isNotEmpty) d.name = cell(row, 'name');
      d.assetClass ??= _assetClass(cell(row, 'asset_class'));
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
            priceUpdatedAt: d.priceOverride != null ? now : null,
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
          priceUpdatedAt: now,
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
