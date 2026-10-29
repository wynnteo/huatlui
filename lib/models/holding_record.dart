import 'enums.dart';

enum InvestmentReviewStatus {
  hold,
  watch,
  addCandidate,
  reduceReview,
  exitReview,
}

/// The persisted part of a holding: what it is, its latest price, and the
/// user's target weight. Quantity / average cost are NOT stored here — they
/// are always derived from the trades (see PortfolioService), so there is no
/// cached number that can drift out of sync with the transaction log.
class HoldingRecord {
  final String id;
  final String accountId;
  final String symbol;
  final String name;
  final AssetClass assetClass;
  final String currency; // the instrument's own trading currency
  final double currentPrice; // in [currency]
  final DateTime? priceUpdatedAt;
  final double? targetPct; // target share of the whole portfolio, 0-100
  final InvestmentReviewStatus reviewStatus;
  final String? investmentThesis;
  final String? reviewNotes;
  final DateTime? nextReviewDate;
  final double? alertBelow;
  final double? alertAbove;

  const HoldingRecord({
    required this.id,
    required this.accountId,
    required this.symbol,
    required this.name,
    this.assetClass = AssetClass.stock,
    required this.currency,
    required this.currentPrice,
    this.priceUpdatedAt,
    this.targetPct,
    this.reviewStatus = InvestmentReviewStatus.hold,
    this.investmentThesis,
    this.reviewNotes,
    this.nextReviewDate,
    this.alertBelow,
    this.alertAbove,
  });

  String get key => keyOf(accountId, symbol);
  static String keyOf(String accountId, String symbol) => '$accountId|${symbol.toUpperCase()}';

  HoldingRecord copyWith({
    double? currentPrice,
    DateTime? priceUpdatedAt,
    double? targetPct,
    bool clearTarget = false,
    InvestmentReviewStatus? reviewStatus,
    String? investmentThesis,
    String? reviewNotes,
    DateTime? nextReviewDate,
    bool clearReviewDate = false,
    double? alertBelow,
    double? alertAbove,
    bool clearAlertBelow = false,
    bool clearAlertAbove = false,
  }) {
    return HoldingRecord(
      id: id,
      accountId: accountId,
      symbol: symbol,
      name: name,
      assetClass: assetClass,
      currency: currency,
      currentPrice: currentPrice ?? this.currentPrice,
      priceUpdatedAt: priceUpdatedAt ?? this.priceUpdatedAt,
      targetPct: clearTarget ? null : (targetPct ?? this.targetPct),
      reviewStatus: reviewStatus ?? this.reviewStatus,
      investmentThesis: investmentThesis ?? this.investmentThesis,
      reviewNotes: reviewNotes ?? this.reviewNotes,
      nextReviewDate: clearReviewDate ? null : (nextReviewDate ?? this.nextReviewDate),
      alertBelow: clearAlertBelow ? null : (alertBelow ?? this.alertBelow),
      alertAbove: clearAlertAbove ? null : (alertAbove ?? this.alertAbove),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'accountId': accountId,
        'symbol': symbol,
        'name': name,
        'assetClass': assetClass.name,
        'currency': currency,
        'currentPrice': currentPrice,
        'priceUpdatedAt': priceUpdatedAt?.toIso8601String(),
        'targetPct': targetPct,
        'reviewStatus': reviewStatus.name,
        'investmentThesis': investmentThesis,
        'reviewNotes': reviewNotes,
        'nextReviewDate': nextReviewDate?.toIso8601String(),
        'alertBelow': alertBelow,
        'alertAbove': alertAbove,
      };

  factory HoldingRecord.fromJson(Map<String, dynamic> j) => HoldingRecord(
        id: j['id'] as String,
        accountId: j['accountId'] as String,
        symbol: j['symbol'] as String,
        name: (j['name'] as String?) ?? (j['symbol'] as String),
        assetClass: enumByName(AssetClass.values, j['assetClass'], AssetClass.stock),
        currency: j['currency'] as String,
        currentPrice: (j['currentPrice'] as num).toDouble(),
        priceUpdatedAt: j['priceUpdatedAt'] == null ? null : DateTime.parse(j['priceUpdatedAt'] as String),
        targetPct: (j['targetPct'] as num?)?.toDouble(),
        reviewStatus: enumByName(InvestmentReviewStatus.values, j['reviewStatus'], InvestmentReviewStatus.hold),
        investmentThesis: j['investmentThesis'] as String?,
        reviewNotes: j['reviewNotes'] as String?,
        nextReviewDate: j['nextReviewDate'] == null ? null : DateTime.parse(j['nextReviewDate'] as String),
        alertBelow: (j['alertBelow'] as num?)?.toDouble(),
        alertAbove: (j['alertAbove'] as num?)?.toDouble(),
      );
}
