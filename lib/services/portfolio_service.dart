import 'dart:math' as math;
import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import '../models/trade.dart';
import 'fx_service.dart';

/// A derived position for one symbol in one account.
class Position {
  final String accountId;
  final String symbol;
  final String name;
  final AssetClass assetClass;
  final String currency;
  final double quantity;
  final double costLocal; // cost of what is still held, instrument currency
  final double costBase; // same, in base currency at historical rates
  final double currentPrice;
  final double marketValueLocal;
  final double marketValueBase; // today's price at today's FX rate
  final double realizedBase; // gains already locked in by sells
  final double dividendsBase; // net dividends received
  final double totalBoughtBase; // everything ever bought, for return %
  final double? targetPct;

  const Position({
    required this.accountId,
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.currency,
    required this.quantity,
    required this.costLocal,
    required this.costBase,
    required this.currentPrice,
    required this.marketValueLocal,
    required this.marketValueBase,
    required this.realizedBase,
    required this.dividendsBase,
    required this.totalBoughtBase,
    this.targetPct,
  });

  bool get isOpen => quantity > 1e-9;
  double get avgCostLocal => quantity > 1e-9 ? costLocal / quantity : 0;
  double get unrealizedLocal => marketValueLocal - costLocal;
  double get unrealizedPct => costLocal > 0 ? unrealizedLocal / costLocal * 100 : 0;
  double get unrealizedBase => marketValueBase - costBase;
  double get totalReturnBase => unrealizedBase + realizedBase + dividendsBase;
}

class PortfolioSummary {
  final double marketValueBase;
  final double costBase; // cost of open positions
  final double unrealizedBase;
  final double realizedBase;
  final double dividendsBase;
  final double totalBoughtBase;

  const PortfolioSummary({
    required this.marketValueBase,
    required this.costBase,
    required this.unrealizedBase,
    required this.realizedBase,
    required this.dividendsBase,
    required this.totalBoughtBase,
  });

  double get capitalGainBase => unrealizedBase + realizedBase;

  /// Capital gain + dividends. Dividends are one part of the return,
  /// never the whole of it.
  double get totalReturnBase => capitalGainBase + dividendsBase;

  /// Price gain/loss only, as a % of everything ever bought. Dividends are
  /// deliberately NOT in here, so a dividend can never hide a price loss.
  double get capitalGainPct => totalBoughtBase > 0 ? capitalGainBase / totalBoughtBase * 100 : 0;

  /// Simple return on everything ever invested (not time-weighted / XIRR).
  double get returnPct => totalBoughtBase > 0 ? totalReturnBase / totalBoughtBase * 100 : 0;
}

enum AllocationGroup { assetClass, account, currency, holding }

enum RiskLevel { none, warning, high }

enum RiskReason { none, overTarget, underTarget, singleHolding }

class AllocationSlice {
  final String key; // raw key (asset class name / account id / currency / symbol)
  final String label; // display label (UI localises asset class names itself)
  final double valueBase;
  final double currentPct;
  final double? targetPct;
  final RiskLevel risk;
  final RiskReason reason;

  const AllocationSlice({
    required this.key,
    required this.label,
    required this.valueBase,
    required this.currentPct,
    this.targetPct,
    this.risk = RiskLevel.none,
    this.reason = RiskReason.none,
  });

  double? get deviation => targetPct == null ? null : currentPct - targetPct!;
}

class PortfolioService {
  final FxService fx;
  final String baseCurrency;

  const PortfolioService({required this.fx, required this.baseCurrency});

  List<Position> positions({
    required List<Trade> trades,
    required List<Dividend> dividends,
    required List<HoldingRecord> holdings,
  }) {
    final meta = {for (final h in holdings) h.key: h};
    final tradesByKey = <String, List<Trade>>{};
    for (final t in trades) {
      tradesByKey.putIfAbsent(HoldingRecord.keyOf(t.accountId, t.symbol), () => []).add(t);
    }
    final divsByKey = <String, List<Dividend>>{};
    for (final d in dividends) {
      divsByKey.putIfAbsent(HoldingRecord.keyOf(d.accountId, d.symbol), () => []).add(d);
    }

    final result = <Position>[];
    final keys = {...tradesByKey.keys, ...divsByKey.keys};
    for (final key in keys) {
      final list = (tradesByKey[key] ?? <Trade>[])
        ..sort((a, b) {
          final c = a.tradeDate.compareTo(b.tradeDate);
          return c != 0 ? c : a.createdAt.compareTo(b.createdAt);
        });
      final divs = divsByKey[key] ?? const <Dividend>[];

      double qty = 0, costLocal = 0, costBase = 0, realizedBase = 0, boughtBase = 0;

      for (final t in list) {
        if (t.type == TradeType.buy) {
          final cashLocal = t.quantity * t.price + t.fees;
          final cashBase = _hist(cashLocal, t.fxRate, t.fxBase);
          qty += t.quantity;
          costLocal += cashLocal;
          costBase += cashBase;
          boughtBase += cashBase;
        } else {
          if (qty <= 1e-9) continue; // selling what we don't hold: ignore bad data
          final sellQty = math.min(t.quantity, qty);
          final share = sellQty / qty;
          final costOutLocal = costLocal * share; // weighted-average cost
          final costOutBase = costBase * share;
          final feeShare = t.quantity > 0 ? t.fees * (sellQty / t.quantity) : 0.0;
          final proceedsLocal = sellQty * t.price - feeShare;
          final proceedsBase = _hist(proceedsLocal, t.fxRate, t.fxBase);
          realizedBase += proceedsBase - costOutBase;
          qty -= sellQty;
          costLocal -= costOutLocal;
          costBase -= costOutBase;
        }
      }

      if (qty <= 1e-9) {
        qty = 0;
        costLocal = 0;
        costBase = 0;
      }

      // A symbol can have dividends but no trades (e.g. an import that only
      // lists dividends); describe it from whichever record exists.
      final accountId = list.isNotEmpty ? list.last.accountId : divs.first.accountId;
      final symbolFallback = list.isNotEmpty ? list.last.symbol : divs.first.symbol;
      final m = meta[key];
      final currency = m?.currency ?? (list.isNotEmpty ? list.last.currency : divs.first.currency);
      final price = m?.currentPrice ?? (list.isNotEmpty ? list.last.price : 0.0);
      final mvLocal = qty * price;
      final mvBase = fx.convert(mvLocal, currency, baseCurrency);

      double divBase = 0;
      for (final d in divs) {
        divBase += _hist(d.netAmount, d.fxRate, d.fxBase);
      }

      result.add(Position(
        accountId: accountId,
        symbol: m?.symbol ?? symbolFallback,
        name: m?.name ?? symbolFallback,
        assetClass: m?.assetClass ?? AssetClass.other,
        currency: currency,
        quantity: qty,
        costLocal: costLocal,
        costBase: costBase,
        currentPrice: price,
        marketValueLocal: mvLocal,
        marketValueBase: mvBase,
        realizedBase: realizedBase,
        dividendsBase: divBase,
        totalBoughtBase: boughtBase,
        targetPct: m?.targetPct,
      ));
    }
    return result;
  }

  PortfolioSummary summary(List<Position> positions) {
    double mv = 0, cost = 0, unreal = 0, real = 0, div = 0, bought = 0;
    for (final p in positions) {
      mv += p.marketValueBase;
      cost += p.costBase;
      unreal += p.unrealizedBase;
      real += p.realizedBase;
      div += p.dividendsBase;
      bought += p.totalBoughtBase;
    }
    return PortfolioSummary(
      marketValueBase: mv,
      costBase: cost,
      unrealizedBase: unreal,
      realizedBase: real,
      dividendsBase: div,
      totalBoughtBase: bought,
    );
  }

  /// Current vs target split of the open positions, with concentration-risk
  /// flags.
  ///
  /// - A group with a target is **high** (red) once it is [deviationThresholdPct]
  ///   points or more away from it, and **warning** (amber) from half that.
  /// - In the per-holding view, any single holding above
  ///   [maxSingleHoldingPct] is **high** even with no target set.
  List<AllocationSlice> allocation(
    List<Position> positions,
    AllocationGroup by, {
    Map<String, String> accountNames = const {},
    double maxSingleHoldingPct = 25,
    double deviationThresholdPct = 5,
  }) {
    final open = positions.where((p) => p.isOpen).toList();
    final total = open.fold<double>(0, (s, p) => s + p.marketValueBase);
    if (total <= 0) return const [];

    String keyOf(Position p) {
      switch (by) {
        case AllocationGroup.assetClass:
          return p.assetClass.name;
        case AllocationGroup.account:
          return p.accountId;
        case AllocationGroup.currency:
          return p.currency;
        case AllocationGroup.holding:
          return p.symbol;
      }
    }

    final value = <String, double>{};
    final target = <String, double>{};
    for (final p in open) {
      final k = keyOf(p);
      value[k] = (value[k] ?? 0) + p.marketValueBase;
      if (p.targetPct != null) target[k] = (target[k] ?? 0) + p.targetPct!;
    }

    final slices = <AllocationSlice>[];
    value.forEach((k, v) {
      final pct = v / total * 100;
      final tgt = target[k];
      var risk = RiskLevel.none;
      var reason = RiskReason.none;

      if (by == AllocationGroup.holding && pct > maxSingleHoldingPct) {
        risk = RiskLevel.high;
        reason = RiskReason.singleHolding;
      }
      if (tgt != null) {
        final dev = pct - tgt;
        if (dev.abs() >= deviationThresholdPct) {
          risk = RiskLevel.high;
          reason = dev > 0 ? RiskReason.overTarget : RiskReason.underTarget;
        } else if (dev.abs() >= deviationThresholdPct / 2 && risk != RiskLevel.high) {
          risk = RiskLevel.warning;
          reason = dev > 0 ? RiskReason.overTarget : RiskReason.underTarget;
        }
      }

      slices.add(AllocationSlice(
        key: k,
        label: by == AllocationGroup.account ? (accountNames[k] ?? k) : k,
        valueBase: v,
        currentPct: pct,
        targetPct: tgt,
        risk: risk,
        reason: reason,
      ));
    });

    slices.sort((a, b) => b.valueBase.compareTo(a.valueBase));
    return slices;
  }

  double _hist(double amount, double fxRate, String fxBase) =>
      fx.toBaseHistorical(amount: amount, fxRate: fxRate, fxBase: fxBase, targetBase: baseCurrency);
}
