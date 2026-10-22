import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../l10n/app_localizations.dart';
import '../models/enums.dart';
import '../theme/app_colors.dart';

/// Green for gains, red for losses, neutral for exactly zero.
Color signColor(BuildContext context, double value) {
  final c = context.colors;
  if (value > 0) return c.gain;
  if (value < 0) return c.loss;
  return c.textPrimary;
}

String assetClassLabel(AppLocalizations t, AssetClass c) {
  switch (c) {
    case AssetClass.stock:
      return t.assetClassStock;
    case AssetClass.etf:
      return t.assetClassEtf;
    case AssetClass.unitTrust:
      return t.assetClassUnitTrust;
    case AssetClass.reit:
      return t.assetClassReit;
    case AssetClass.bond:
      return t.assetClassBond;
    case AssetClass.cash:
      return t.assetClassCash;
    case AssetClass.other:
      return t.assetClassOther;
  }
}

/// 10 -> "10", 12.5 -> "12.5", 0.125 -> "0.125" (no trailing zeros).
String fmtQty(double q) => NumberFormat('#,##0.####').format(q);

/// Numeric date so it reads the same in every language.
String fmtDate(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

class HairlineDivider extends StatelessWidget {
  const HairlineDivider({super.key});

  @override
  Widget build(BuildContext context) => Divider(height: 1, thickness: 1, color: context.colors.outline);
}

class ScreenTitle extends StatelessWidget {
  final String text;
  const ScreenTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Text(text, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: context.colors.textPrimary)),
      );
}
