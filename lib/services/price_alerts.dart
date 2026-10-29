import '../models/holding_record.dart';

/// Price conditions are assessed against the instrument's own quote currency.
bool priceAlertTriggered({
  required double price,
  double? atOrBelow,
  double? atOrAbove,
}) {
  if (!price.isFinite || price <= 0) return false;
  return (atOrBelow != null && price <= atOrBelow) ||
      (atOrAbove != null && price >= atOrAbove);
}

bool validPriceThreshold(double? value) =>
    value == null || (value.isFinite && value > 0);

bool holdingPriceAlertTriggered(HoldingRecord holding) =>
    priceAlertTriggered(
      price: holding.currentPrice,
      atOrBelow: holding.alertBelow,
      atOrAbove: holding.alertAbove,
    );
