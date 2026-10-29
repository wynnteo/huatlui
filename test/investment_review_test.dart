import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/holding_record.dart';
import 'package:huatlui/screens/investment_review_editor.dart';

void main() {
  final record = HoldingRecord(
    id: 'record-1',
    accountId: 'account-1',
    symbol: 'F9D.SI',
    name: 'Boustead',
    currency: 'SGD',
    currentPrice: 2.1,
    reviewStatus: InvestmentReviewStatus.reduceReview,
    investmentThesis: 'Hold for cash flow',
    reviewNotes: 'Review if margins weaken',
    nextReviewDate: DateTime(2026, 10, 29),
  );

  test('JSON round trip preserves review fields', () {
    final loaded = HoldingRecord.fromJson(record.toJson());
    expect(loaded.reviewStatus, InvestmentReviewStatus.reduceReview);
    expect(loaded.investmentThesis, 'Hold for cash flow');
    expect(loaded.reviewNotes, 'Review if margins weaken');
    expect(loaded.nextReviewDate, DateTime(2026, 10, 29));
  });

  test('old backup holdings default to Hold', () {
    final old = record.toJson()
      ..remove('reviewStatus')
      ..remove('investmentThesis')
      ..remove('reviewNotes')
      ..remove('nextReviewDate');
    final loaded = HoldingRecord.fromJson(old);
    expect(loaded.reviewStatus, InvestmentReviewStatus.hold);
    expect(loaded.nextReviewDate, isNull);
  });

  test('price updates retain review metadata', () {
    final updated = record.copyWith(
      currentPrice: 2.5,
      priceUpdatedAt: DateTime(2026, 10, 29, 14),
    );
    expect(updated.reviewStatus, InvestmentReviewStatus.reduceReview);
    expect(updated.investmentThesis, record.investmentThesis);
    expect(updated.nextReviewDate, record.nextReviewDate);
  });

  test('due date respects local calendar day', () {
    expect(reviewDue(record, DateTime(2026, 10, 28, 23)), isFalse);
    expect(reviewDue(record, DateTime(2026, 10, 29, 0)), isTrue);
    expect(reviewDue(record, DateTime(2026, 10, 31)), isTrue);
    expect(reviewDue(record.copyWith(clearReviewDate: true), DateTime(2026, 11, 1)), isFalse);
  });

  test('status label offers English and Chinese', () {
    expect(reviewStatusLabel(InvestmentReviewStatus.addCandidate, false), 'Add Candidate');
    expect(reviewStatusLabel(InvestmentReviewStatus.addCandidate, true), '考虑加仓');
  });
}
