import 'package:flutter_test/flutter_test.dart';
import 'package:huatlui/models/holding_record.dart';
import 'package:huatlui/services/price_alerts.dart';

HoldingRecord holding(double price, {double? below, double? above}) =>
    HoldingRecord(
      id: 'one', accountId: 'broker', symbol: 'TEST.SI',
      name: 'Test', currency: 'SGD', currentPrice: price,
      alertBelow: below, alertAbove: above,
    );

void main() {
  test('lower target triggers at or below threshold', () {
    expect(holdingPriceAlertTriggered(holding(1.25, below: 1.25)), isTrue);
    expect(holdingPriceAlertTriggered(holding(1.26, below: 1.25)), isFalse);
  });
  test('upper target triggers at or above threshold', () {
    expect(holdingPriceAlertTriggered(holding(2.3, above: 2.3)), isTrue);
    expect(holdingPriceAlertTriggered(holding(2.29, above: 2.3)), isFalse);
  });
  test('invalid or missing prices never trigger', () {
    expect(holdingPriceAlertTriggered(holding(0, below: 1)), isFalse);
    expect(holdingPriceAlertTriggered(holding(double.nan, above: 1)), isFalse);
    expect(holdingPriceAlertTriggered(holding(1)), isFalse);
  });
  test('thresholds survive persistence and price refresh copy', () {
    final original = holding(2.0, below: 1.5, above: 2.5);
    final parsed = HoldingRecord.fromJson(original.toJson());
    final refreshed = parsed.copyWith(
      currentPrice: 2.6, priceUpdatedAt: DateTime(2026, 10, 29));
    expect(refreshed.alertBelow, 1.5);
    expect(refreshed.alertAbove, 2.5);
    expect(holdingPriceAlertTriggered(refreshed), isTrue);
  });
  test('old holdings deserialize without alert thresholds', () {
    final json = holding(2).toJson()
      ..remove('alertBelow')..remove('alertAbove');
    final record = HoldingRecord.fromJson(json);
    expect(record.alertBelow, isNull);
    expect(record.alertAbove, isNull);
    expect(record.copyWith(alertBelow: 1).copyWith(clearAlertBelow: true).alertBelow, isNull);
  });
  test('invalid alert inputs are rejected by validator', () {
    expect(validPriceThreshold(null), isTrue);
    expect(validPriceThreshold(1), isTrue);
    expect(validPriceThreshold(0), isFalse);
    expect(validPriceThreshold(-1), isFalse);
    expect(validPriceThreshold(double.infinity), isFalse);
  });
}
