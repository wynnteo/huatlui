import 'enums.dart';

/// One BUY or SELL. Dividends are a separate model.
///
/// [fxRate] converts [currency] -> [fxBase] and is recorded on the trade
/// date and never recalculated, so historical cost basis doesn't move when
/// exchange rates do. [fxBase] remembers which base currency that rate was
/// recorded against, so changing the base currency later can still convert
/// correctly (see FxService.toBaseHistorical).
class Trade {
  final String id;
  final String accountId;
  final String symbol;
  final TradeType type;
  final DateTime tradeDate;
  final double quantity;
  final double price; // per unit, in [currency]
  final String currency;
  final double fxRate;
  final String fxBase;
  final double commission;
  final double otherFees;
  final String? notes;
  final DateTime createdAt;

  const Trade({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.type,
    required this.tradeDate,
    required this.quantity,
    required this.price,
    required this.currency,
    this.fxRate = 1.0,
    required this.fxBase,
    this.commission = 0,
    this.otherFees = 0,
    this.notes,
    required this.createdAt,
  });

  double get fees => commission + otherFees;

  /// Cash impact in [currency]: a buy costs price*qty plus fees, a sell
  /// brings in price*qty minus fees.
  double get netAmount => type == TradeType.buy ? quantity * price + fees : quantity * price - fees;

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'symbol': symbol,
        'type': type.name,
        'tradeDate': tradeDate.toIso8601String(),
        'quantity': quantity,
        'price': price,
        'currency': currency,
        'fxRate': fxRate,
        'fxBase': fxBase,
        'commission': commission,
        'otherFees': otherFees,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Trade.fromJson(Map<String, dynamic> j) => Trade(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        symbol: j['symbol'] as String,
        type: enumByName(TradeType.values, j['type'], TradeType.buy),
        tradeDate: DateTime.parse(j['tradeDate'] as String),
        quantity: (j['quantity'] as num).toDouble(),
        price: (j['price'] as num).toDouble(),
        currency: j['currency'] as String,
        fxRate: ((j['fxRate'] as num?) ?? 1).toDouble(),
        fxBase: (j['fxBase'] as String?) ?? (j['currency'] as String),
        commission: ((j['commission'] as num?) ?? 0).toDouble(),
        otherFees: ((j['otherFees'] as num?) ?? 0).toDouble(),
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
