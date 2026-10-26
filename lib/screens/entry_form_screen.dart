import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../app_scope.dart';
import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/trade.dart';
import '../services/activity.dart';
import '../services/parse_utils.dart';
import '../services/portfolio_service.dart';
import '../theme/app_colors.dart';
import '../widgets/activity_actions.dart';
import '../widgets/ui_helpers.dart';

enum EntryKind { buy, sell, dividend }

/// One form for Buy / Sell / Dividend. Fields that don't apply to the chosen
/// kind are hidden, and a symbol you already hold fills in its currency.
///
/// Also edits an existing entry (pass [editTrade] or [editDividend]; the
/// account and symbol are then fixed, so a wrong one means delete and re-add),
/// and can open pre-filled for one holding ([prefillAccountId] + [prefillSymbol]).
class EntryFormScreen extends StatefulWidget {
  final EntryKind initialKind;
  final Trade? editTrade;
  final Dividend? editDividend;
  final String? prefillAccountId;
  final String? prefillSymbol;
  const EntryFormScreen({
    super.key,
    this.initialKind = EntryKind.buy,
    this.editTrade,
    this.editDividend,
    this.prefillAccountId,
    this.prefillSymbol,
  });

  @override
  State<EntryFormScreen> createState() => _EntryFormScreenState();
}

class _EntryFormScreenState extends State<EntryFormScreen> {
  static const _newAccountValue = '__new__';

  late EntryKind _kind;
  String? _accountId;
  final _newAccountCtrl = TextEditingController();
  final _symbolCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _qtyCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _feesCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  final _fxCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  AssetClass _assetClass = AssetClass.stock;
  String _currency = settings.baseCurrency;
  DateTime _date = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  bool _fxTouched = false;

  @override
  void initState() {
    super.initState();
    final et = widget.editTrade;
    final ed = widget.editDividend;
    _kind = ed != null
        ? EntryKind.dividend
        : et != null
            ? (et.type == TradeType.buy ? EntryKind.buy : EntryKind.sell)
            : widget.initialKind;
    _accountId = et?.accountId ??
        ed?.accountId ??
        widget.prefillAccountId ??
        (repo.accounts.isNotEmpty ? repo.accounts.first.id : _newAccountValue);
    if (widget.prefillSymbol != null) _symbolCtrl.text = widget.prefillSymbol!;
    if (et != null) {
      _symbolCtrl.text = et.symbol;
      _date = DateTime(et.tradeDate.year, et.tradeDate.month, et.tradeDate.day);
      _qtyCtrl.text = _num(et.quantity);
      _priceCtrl.text = _num(et.price);
      _feesCtrl.text = et.fees == 0 ? '' : _num(et.fees);
      _fxCtrl.text = _num(et.fxRate);
      _fxTouched = true; // keep the rate that was recorded
      _notesCtrl.text = et.notes ?? '';
      _currency = et.currency;
    }
    if (ed != null) {
      _symbolCtrl.text = ed.symbol;
      _date = DateTime(ed.paymentDate.year, ed.paymentDate.month, ed.paymentDate.day);
      _amountCtrl.text = _num(ed.grossAmount);
      _taxCtrl.text = ed.withholdingTax == 0 ? '' : _num(ed.withholdingTax);
      _fxCtrl.text = _num(ed.fxRate);
      _fxTouched = true;
      _notesCtrl.text = ed.notes ?? '';
      _currency = ed.currency;
    }
    _syncFx();
  }

  bool get _editing => widget.editTrade != null || widget.editDividend != null;

  /// The base currency the stored exchange rate was recorded against. When
  /// editing it is kept, so changing your base currency later doesn't
  /// silently reinterpret an old rate.
  String get _fxBase => widget.editTrade?.fxBase ?? widget.editDividend?.fxBase ?? settings.baseCurrency;

  static String _num(double v) {
    var s = v.toStringAsFixed(6);
    if (s.contains('.')) s = s.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  Future<void> _delete() async {
    final et = widget.editTrade;
    final ed = widget.editDividend;
    final deleted = et != null
        ? await deleteTradeChecked(context, et)
        : ed != null
            ? await deleteDividendChecked(context, ed)
            : false;
    if (deleted && mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    for (final c in [_newAccountCtrl, _symbolCtrl, _nameCtrl, _qtyCtrl, _priceCtrl, _feesCtrl, _amountCtrl, _taxCtrl, _fxCtrl, _notesCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isNewAccount => _accountId == _newAccountValue;

  HoldingRecord? _holding() {
    if (_isNewAccount || _accountId == null) return null;
    final sym = _symbolCtrl.text.trim();
    if (sym.isEmpty) return null;
    return repo.holdingFor(_accountId!, sym);
  }

  String get _effectiveCurrency => _holding()?.currency ?? _currency;

  /// Pre-fill the FX rate from the built-in table until the user edits it.
  void _syncFx() {
    if (_fxTouched) return;
    _fxCtrl.text = fx.rate(_effectiveCurrency, _fxBase).toStringAsFixed(4);
  }

  void _toast(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = DateTime(picked.year, picked.month, picked.day));
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context)!;
    final base = settings.baseCurrency;
    final fxBase = _fxBase;

    // --- account ---
    Account? newAccount;
    String accountId;
    if (_isNewAccount) {
      final name = _newAccountCtrl.text.trim();
      if (name.isEmpty) return _toast(t.errAccountRequired);
      newAccount = Account(id: const Uuid().v4(), name: name, createdAt: DateTime.now());
      accountId = newAccount.id;
    } else {
      accountId = _accountId!;
    }

    // --- symbol / holding ---
    final symbol = _symbolCtrl.text.trim().toUpperCase();
    if (symbol.isEmpty) return _toast(t.errSymbolRequired);
    final holding = newAccount == null ? repo.holdingFor(accountId, symbol) : null;
    if (_kind == EntryKind.dividend && holding == null && !_editing) return _toast(t.errDividendNeedsHolding);
    final currency = widget.editTrade?.currency ?? widget.editDividend?.currency ?? holding?.currency ?? _currency;

    // --- numbers ---
    double fxRate = 1.0;
    if (currency != fxBase) {
      final v = parseNumber(_fxCtrl.text);
      if (v == null || v <= 0) return _toast(t.errFxRate);
      fxRate = v;
    }

    final now = DateTime.now();
    const uuid = Uuid();

    if (_kind == EntryKind.dividend) {
      final gross = parseNumber(_amountCtrl.text);
      if (gross == null || gross <= 0) return _toast(t.errNumber(t.fieldGrossAmount));
      final taxText = _taxCtrl.text.trim();
      final tax = taxText.isEmpty ? 0.0 : parseNumber(taxText);
      if (tax == null || tax < 0) return _toast(t.errNumber(t.fieldWithholdingTax));

      await repo.putDividend(Dividend(
        id: widget.editDividend?.id ?? uuid.v4(),
        accountId: accountId,
        symbol: widget.editDividend?.symbol ?? holding!.symbol,
        currency: currency,
        fxRate: fxRate,
        fxBase: fxBase,
        grossAmount: gross,
        withholdingTax: tax,
        paymentDate: _date,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: widget.editDividend?.createdAt ?? now,
      ));
    } else {
      final qty = parseNumber(_qtyCtrl.text);
      if (qty == null || qty <= 0) return _toast(t.errNumber(t.fieldQuantity));
      final price = parseNumber(_priceCtrl.text);
      if (price == null || price < 0) return _toast(t.errNumber(t.fieldPrice));
      final feesText = _feesCtrl.text.trim();
      final fees = feesText.isEmpty ? 0.0 : parseNumber(feesText);
      if (fees == null || fees < 0) return _toast(t.errNumber(t.fieldFees));

      final old = widget.editTrade;
      if (old != null) {
        // Editing: refuse only if the change leaves a sale bigger than the units held.
        final candidate = Trade(
          id: old.id,
          accountId: old.accountId,
          symbol: old.symbol,
          type: _kind == EntryKind.buy ? TradeType.buy : TradeType.sell,
          tradeDate: _date,
          quantity: qty,
          price: price,
          currency: old.currency,
          fxRate: fxRate,
          fxBase: fxBase,
          commission: fees,
          createdAt: old.createdAt,
        );
        final next = [for (final x in repo.trades) if (x.id != old.id) x, candidate];
        if (changeBreaksHoldings(repo.trades, next)) return _toast(t.errBreaksHoldings);
      }

      if (_kind == EntryKind.sell && old == null) {
        final svc = PortfolioService(fx: fx, baseCurrency: base);
        final key = HoldingRecord.keyOf(accountId, symbol);
        final held = svc
            .positions(trades: repo.trades, dividends: repo.dividends, holdings: repo.holdings)
            .where((p) => HoldingRecord.keyOf(p.accountId, p.symbol) == key)
            .fold<double>(0, (s, p) => s + p.quantity);
        if (qty > held + 1e-9) return _toast(t.errOnlyHold(fmtQty(held), symbol));
      }

      if (newAccount != null) await repo.putAccount(newAccount);
      var createdHolding = false;
      if (holding == null && !_editing) {
        createdHolding = true;
        await repo.putHolding(HoldingRecord(
          id: uuid.v4(),
          accountId: accountId,
          symbol: symbol,
          name: _nameCtrl.text.trim().isEmpty ? symbol : _nameCtrl.text.trim(),
          assetClass: _assetClass,
          currency: currency,
          // Placeholder until the first real price is fetched (below).
          currentPrice: price,
        ));
      }
      await repo.putTrade(Trade(
        id: widget.editTrade?.id ?? uuid.v4(),
        accountId: accountId,
        symbol: symbol,
        type: _kind == EntryKind.buy ? TradeType.buy : TradeType.sell,
        tradeDate: _date,
        quantity: qty,
        price: price,
        currency: currency,
        fxRate: fxRate,
        fxBase: fxBase,
        commission: fees,
        notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
        createdAt: widget.editTrade?.createdAt ?? now,
      ));
      // A brand-new holding has no real price yet: fetch it now.
      if (createdHolding) prices.refreshAll();
      if (mounted) Navigator.pop(context);
      return;
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final c = context.colors;
    final base = settings.baseCurrency;
    final holding = _holding();
    final currency = _effectiveCurrency;
    final fxBase = _fxBase;
    final accountHoldings = _isNewAccount ? <HoldingRecord>[] : repo.holdings.where((h) => h.accountId == _accountId).toList();

    Widget gap([double h = 16]) => SizedBox(height: h);

    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? t.editEntry : t.addEntry),
        actions: [
          if (_editing) IconButton(icon: const Icon(Icons.delete_outline), tooltip: t.delete, onPressed: _delete),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            if (widget.editDividend == null) ...[
              SegmentedButton<EntryKind>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(value: EntryKind.buy, label: Text(t.buy)),
                  ButtonSegment(value: EntryKind.sell, label: Text(t.sell)),
                  if (widget.editTrade == null) ButtonSegment(value: EntryKind.dividend, label: Text(t.dividend)),
                ],
                selected: {_kind},
                onSelectionChanged: (s) => setState(() => _kind = s.first),
              ),
              gap(20),
            ],

            DropdownButtonFormField<String>(
              value: _accountId,
              decoration: InputDecoration(labelText: t.fieldAccount),
              items: [
                for (final a in repo.accounts) DropdownMenuItem(value: a.id, child: Text(a.name)),
                DropdownMenuItem(value: _newAccountValue, child: Text(t.newAccountOption)),
              ],
              onChanged: _editing
                  ? null
                  : (v) => setState(() {
                        _accountId = v;
                        _syncFx();
                      }),
            ),
            if (_isNewAccount) ...[
              gap(12),
              TextField(
                controller: _newAccountCtrl,
                decoration: InputDecoration(labelText: t.fieldNewAccountName, hintText: t.createAccountHint),
              ),
            ],
            gap(),

            TextField(
              controller: _symbolCtrl,
              enabled: !_editing,
              textCapitalization: TextCapitalization.characters,
              onChanged: (_) => setState(_syncFx),
              decoration: InputDecoration(labelText: t.fieldSymbol, hintText: t.symbolHint),
            ),
            if (accountHoldings.isNotEmpty && !_editing) ...[
              gap(10),
              Text(t.pickHoldingHint, style: TextStyle(fontSize: 12, color: c.textSecondary)),
              gap(6),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  for (final h in accountHoldings)
                    ActionChip(
                      label: Text(h.symbol),
                      onPressed: () => setState(() {
                        _symbolCtrl.text = h.symbol;
                        _syncFx();
                      }),
                    ),
                ],
              ),
            ],
            gap(),

            if (holding == null && _kind != EntryKind.dividend) ...[
              TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: t.fieldName)),
              gap(),
              DropdownButtonFormField<AssetClass>(
                value: _assetClass,
                decoration: InputDecoration(labelText: t.fieldAssetClass),
                items: [for (final a in AssetClass.values) DropdownMenuItem(value: a, child: Text(assetClassLabel(t, a)))],
                onChanged: (v) => setState(() => _assetClass = v ?? AssetClass.stock),
              ),
              gap(),
              DropdownButtonFormField<String>(
                value: _currency,
                decoration: InputDecoration(labelText: t.fieldCurrency),
                items: [for (final code in fx.supportedCurrencies) DropdownMenuItem(value: code, child: Text(code))],
                onChanged: (v) => setState(() {
                  _currency = v ?? base;
                  _syncFx();
                }),
              ),
              gap(),
            ] else if (holding != null) ...[
              InputDecorator(
                decoration: InputDecoration(labelText: t.fieldCurrency),
                child: Text('$currency · ${holding.name}', style: TextStyle(color: c.textPrimary)),
              ),
              gap(),
            ],

            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(labelText: t.fieldDate, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
                child: Text(fmtDate(_date), style: TextStyle(color: c.textPrimary)),
              ),
            ),
            gap(),

            if (_kind != EntryKind.dividend) ...[
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _qtyCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.fieldQuantity),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _priceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: '${t.fieldPrice} ($currency)'),
                    ),
                  ),
                ],
              ),
              gap(),
              TextField(
                controller: _feesCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '${t.fieldFees} ($currency)'),
              ),
            ] else ...[
              TextField(
                controller: _amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '${t.fieldGrossAmount} ($currency)'),
              ),
              gap(),
              TextField(
                controller: _taxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(labelText: '${t.fieldWithholdingTax} ($currency)'),
              ),
            ],
            gap(),

            if (currency != fxBase) ...[
              TextField(
                controller: _fxCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => _fxTouched = true,
                decoration: InputDecoration(labelText: t.fieldFxRate, helperText: t.fxRateHelp(currency, fxBase), helperMaxLines: 3),
              ),
              gap(),
            ],

            TextField(controller: _notesCtrl, decoration: InputDecoration(labelText: t.fieldNotes)),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: FilledButton(onPressed: _save, child: Text(t.save)),
        ),
      ),
    );
  }
}
