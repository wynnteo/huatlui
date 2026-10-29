import '../models/dividend.dart';
import '../models/enums.dart';
import '../models/holding_record.dart';
import 'portfolio_service.dart';

/// Net dividends by payment date, including withholding tax deductions.
/// The record is account scoped: the same symbol in another broker is excluded.
double netDividendsForYear({
  required Iterable<Dividend> dividends,
  required String accountId,
  required String symbol,
  required int year,
}) {
  final key = HoldingRecord.keyOf(accountId, symbol);
  return dividends
      .where((d) =>
          HoldingRecord.keyOf(d.accountId, d.symbol) == key &&
          d.paymentDate.year == year)
      .fold<double>(0, (total, dividend) => total + dividend.netAmount);
}

enum HoldingSort { symbol, marketValue, profitLoss, profitLossPct }

List<Position> filterAndSortHoldings({
  required Iterable<Position> positions,
  String? accountId,
  AssetClass? assetClass,
  HoldingSort sort = HoldingSort.symbol,
  bool descending = false,
}) {
  final result = positions.where((p) =>
      p.isOpen &&
      (accountId == null || p.accountId == accountId) &&
      (assetClass == null || p.assetClass == assetClass)).toList();

  int compare(Position a, Position b) {
    var value = switch (sort) {
      HoldingSort.symbol => a.symbol.toUpperCase().compareTo(b.symbol.toUpperCase()),
      HoldingSort.marketValue => a.marketValueBase.compareTo(b.marketValueBase),
      HoldingSort.profitLoss => a.unrealizedBase.compareTo(b.unrealizedBase),
      HoldingSort.profitLossPct => a.unrealizedPct.compareTo(b.unrealizedPct),
    };
    if (descending) value = -value;
    return value != 0 ? value : (a.accountId.compareTo(b.accountId) != 0
      ? a.accountId.compareTo(b.accountId)
      : a.symbol.compareTo(b.symbol));
  }
  result.sort(compare);
  return result;
}
