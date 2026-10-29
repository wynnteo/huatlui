import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/account.dart';
import '../models/dividend.dart';
import '../models/holding_record.dart';
import '../models/price_point.dart';
import '../models/trade.dart';
import 'csv_import.dart';
import 'activity.dart';
import 'demo_data.dart';
import 'portfolio_backup.dart';
import 'portfolio_write_queue.dart';

/// Local storage for the POC. Everything is saved as plain JSON maps in
/// Hive boxes (no type adapters, so no build_runner step), and kept in
/// memory as lists that screens listen to.
///
/// Later, an API-backed implementation can replace this class without the
/// screens changing: they only ever read the lists and call these methods.
class PortfolioRepository extends ChangeNotifier {
  late final Box<dynamic> _accountsBox;
  late final Box<dynamic> _holdingsBox;
  late final Box<dynamic> _tradesBox;
  late final Box<dynamic> _dividendsBox;
  late final Box<dynamic> _priceBox;
  late final Box<dynamic> _restoreJournal;
  final PortfolioWriteQueue _writes = PortfolioWriteQueue();

  List<Box<dynamic>> get _dataBoxes => [
    _accountsBox, _holdingsBox, _tradesBox, _dividendsBox, _priceBox,
  ];

  /// Persistent undo record written before touching any portfolio box.
  /// If the app is killed during replacement, initialization restores it.
  Future<void> _recoverInterruptedRestore() async {
    final entry = _restoreJournal.get('pending');
    if (entry == null) return;
    if (entry is! Map) throw StateError('Invalid restore recovery journal');
    if (!shouldRollbackRestoreJournal(entry['state']) && entry['state'] == 'committed') {
      await _restoreJournal.delete('pending');
      return;
    }
    if (entry['state'] != 'prepared' || entry['snapshots'] is! List ||
        (entry['snapshots'] as List).length != _dataBoxes.length) {
      throw StateError('Invalid restore recovery journal');
    }
    final snapshots = entry['snapshots'] as List;
    for (var i = 0; i < _dataBoxes.length; i++) {
      final snapshot = snapshots[i];
      if (snapshot is! Map) throw StateError('Corrupt restore recovery snapshot');
      final copy = <dynamic, dynamic>{for (final key in snapshot.keys) key: snapshot[key]};
      await _dataBoxes[i].clear();
      await _dataBoxes[i].putAll(copy);
    }
    await _restoreJournal.delete('pending');
  }

  List<Account> accounts = [];
  List<HoldingRecord> holdings = [];
  List<Trade> trades = [];
  List<Dividend> dividends = [];

  /// Daily closing prices per symbol (upper-case), oldest first. Stocks get
  /// the full history from Yahoo; unit trusts build up one snapshot per refresh.
  Map<String, List<PricePoint>> priceHistory = {};

  Future<void> init() async {
    await Hive.initFlutter();
    _accountsBox = await Hive.openBox<dynamic>('accounts');
    _holdingsBox = await Hive.openBox<dynamic>('holdings');
    _tradesBox = await Hive.openBox<dynamic>('trades');
    _dividendsBox = await Hive.openBox<dynamic>('dividends');
    _priceBox = await Hive.openBox<dynamic>('price_history');
    _restoreJournal = await Hive.openBox<dynamic>('portfolio_restore_journal_v1');
    await _recoverInterruptedRestore();
    _reload();
    _reloadPrices();
  }

  Map<String, dynamic> _asMap(dynamic v) => Map<String, dynamic>.from(v as Map);

  void _reload() {
    accounts = _accountsBox.values.map((e) => Account.fromJson(_asMap(e))).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    holdings = _holdingsBox.values.map((e) => HoldingRecord.fromJson(_asMap(e))).toList();
    trades = _tradesBox.values.map((e) => Trade.fromJson(_asMap(e))).toList();
    dividends = _dividendsBox.values.map((e) => Dividend.fromJson(_asMap(e))).toList();
  }

  void _reloadPrices() {
    final map = <String, List<PricePoint>>{};
    for (final k in _priceBox.keys) {
      final raw = _priceBox.get(k);
      if (raw is! List) continue;
      final list = <PricePoint>[];
      for (final e in raw) {
        list.add(PricePoint.fromJson(e));
      }
      list.sort((a, b) => a.date.compareTo(b.date));
      map[k as String] = list;
    }
    priceHistory = map;
  }

  /// Saves a whole price refresh in one go: new prices on the holdings, and
  /// the day-by-day history merged into what is already stored (newer wins).
  Future<void> applyPriceRefresh(List<HoldingRecord> updatedHoldings, Map<String, List<PricePoint>> history) async {
    return _writes.run(() async {
    for (final h in updatedHoldings) {
      await _holdingsBox.put(h.id, h.toJson());
    }
    for (final e in history.entries) {
      final merged = <int, double>{};
      for (final p in priceHistory[e.key] ?? const <PricePoint>[]) {
        merged[p.date.millisecondsSinceEpoch] = p.price;
      }
      for (final p in e.value) {
        merged[p.date.millisecondsSinceEpoch] = p.price;
      }
      final days = merged.keys.toList()..sort();
      await _priceBox.put(e.key, [
        for (final d in days) [d, merged[d]!],
      ]);
    }
    _reloadPrices();
    await _changed();
  
    });
  }

  Future<void> _changed() async {
    _reload();
    notifyListeners();
  }

  HoldingRecord? holdingFor(String accountId, String symbol) {
    final key = HoldingRecord.keyOf(accountId, symbol);
    for (final h in holdings) {
      if (h.key == key) return h;
    }
    return null;
  }

  /// Writes everything from a CSV import in one go (one reload, one notify).
  Future<void> applyImport(ImportPlan plan) async {
    return _writes.run(() async {
    // Validate the complete post-import history before making any writes.
    if (!tradesAreConsistent([...trades, ...plan.trades])) {
      throw StateError('Import would create a sale exceeding available shares');
    }
    for (final a in plan.newAccounts) {
      await _accountsBox.put(a.id, a.toJson());
    }
    for (final h in plan.holdingUpserts) {
      await _holdingsBox.put(h.id, h.toJson());
    }
    for (final t in plan.trades) {
      await _tradesBox.put(t.id, t.toJson());
    }
    for (final d in plan.dividends) {
      await _dividendsBox.put(d.id, d.toJson());
    }
    await _changed();
  
    });
  }

  Future<void> putAccount(Account a) async {
    return _writes.run(() async {
    await _accountsBox.put(a.id, a.toJson());
    await _changed();
  
    });
  }

  Future<void> putHolding(HoldingRecord h) async {
    return _writes.run(() async {
    await _holdingsBox.put(h.id, h.toJson());
    await _changed();
  
    });
  }

  Future<void> putTrade(Trade t) async {
    return _writes.run(() async {
    await _tradesBox.put(t.id, t.toJson());
    await _changed();
  
    });
  }

  Future<void> putDividend(Dividend d) async {
    return _writes.run(() async {
    await _dividendsBox.put(d.id, d.toJson());
    await _changed();
  
    });
  }

  Future<void> deleteTrade(String id) async {
    return _writes.run(() async {
    await _tradesBox.delete(id);
    await _changed();
  
    });
  }

  Future<void> deleteDividend(String id) async {
    return _writes.run(() async {
    await _dividendsBox.delete(id);
    await _changed();
  
    });
  }

  Future<void> loadDemo() async {
    return _writes.run(() async {
    final demo = DemoData.build();
    for (final a in demo.accounts) {
      await _accountsBox.put(a.id, a.toJson());
    }
    for (final h in demo.holdings) {
      await _holdingsBox.put(h.id, h.toJson());
    }
    for (final t in demo.trades) {
      await _tradesBox.put(t.id, t.toJson());
    }
    for (final d in demo.dividends) {
      await _dividendsBox.put(d.id, d.toJson());
    }
    await _changed();
  
    });
  }

  /// Crash-resilient restore using a persistent undo journal.
  /// A prepared journal is recovered on the next launch before loading data.
  Future<void> restoreBackup(PortfolioBackup backup) async {
    backup.validate();
    return _writes.run(() async {
      // Resolve a previously interrupted operation before starting another.
      await _recoverInterruptedRestore();
      final boxes = _dataBoxes;
      final old = [
        for (final box in boxes)
          <dynamic, dynamic>{for (final key in box.keys) key: box.get(key)},
      ];
      final next = <Map<dynamic, dynamic>>[
        {for (final x in backup.accounts) x.id: x.toJson()},
        {for (final x in backup.holdings) x.id: x.toJson()},
        {for (final x in backup.trades) x.id: x.toJson()},
        {for (final x in backup.dividends) x.id: x.toJson()},
        {
          for (final entry in backup.priceHistory.entries)
            entry.key: [for (final point in entry.value) point.toJson()],
        },
      ];
      await _restoreJournal.put('pending', {
        'state': 'prepared',
        'snapshots': old,
      });
      try {
        for (var i = 0; i < boxes.length; i++) {
          await boxes[i].clear();
          await boxes[i].putAll(next[i]);
        }
        // Mark the replacement committed before deleting its undo record.
        await _restoreJournal.put('pending', {'state': 'committed'});
        _reloadPrices();
        await _changed();
      } catch (_) {
        // Preserve the journal if recovery also fails: next launch retries.
        await _recoverInterruptedRestore();
        _reloadPrices();
        await _changed();
        rethrow;
      }
      // A crash after committing but before deleting the marker keeps the new
      // data; the startup recovery removes only the committed marker.
      await _restoreJournal.delete('pending');
    });
  }

  Future<void> clearAll() async {
    return _writes.run(() async {
    await _accountsBox.clear();
    await _holdingsBox.clear();
    await _tradesBox.clear();
    await _dividendsBox.clear();
    await _priceBox.clear();
    _reloadPrices();
    await _changed();
  
    });
  }
}
