/// A dividend payment. [fxRate]/[fxBase] work exactly like on Trade: the
/// rate on the payment date, recorded once.
class Dividend {
  final String id;
  final String accountId;
  final String symbol;
  final String currency;
  final double fxRate;
  final String fxBase;
  final double grossAmount;
  final double withholdingTax;
  final DateTime paymentDate;
  final DateTime? exDividendDate;
  final bool reinvested;
  final String? notes;
  final DateTime createdAt;

  const Dividend({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.currency,
    this.fxRate = 1.0,
    required this.fxBase,
    required this.grossAmount,
    this.withholdingTax = 0,
    required this.paymentDate,
    this.exDividendDate,
    this.reinvested = false,
    this.notes,
    required this.createdAt,
  });

  double get netAmount => grossAmount - withholdingTax;

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'symbol': symbol,
        'currency': currency,
        'fxRate': fxRate,
        'fxBase': fxBase,
        'grossAmount': grossAmount,
        'withholdingTax': withholdingTax,
        'paymentDate': paymentDate.toIso8601String(),
        'exDividendDate': exDividendDate?.toIso8601String(),
        'reinvested': reinvested,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Dividend.fromJson(Map<String, dynamic> j) => Dividend(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        symbol: j['symbol'] as String,
        currency: j['currency'] as String,
        fxRate: ((j['fxRate'] as num?) ?? 1).toDouble(),
        fxBase: (j['fxBase'] as String?) ?? (j['currency'] as String),
        grossAmount: (j['grossAmount'] as num).toDouble(),
        withholdingTax: ((j['withholdingTax'] as num?) ?? 0).toDouble(),
        paymentDate: DateTime.parse(j['paymentDate'] as String),
        exDividendDate: j['exDividendDate'] == null ? null : DateTime.parse(j['exDividendDate'] as String),
        reinvested: (j['reinvested'] as bool?) ?? false,
        notes: j['notes'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}
