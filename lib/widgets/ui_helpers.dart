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
    case AssetClass.crypto:
      return t.assetClassCrypto;
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
        padding: const EdgeInsets.only(bottom: 20),
        child: Text(
          text,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.6, color: context.colors.textPrimary),
        ),
      );
}

/// Small quiet heading that sits above a block of content.
class SectionLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry padding;
  const SectionLabel(this.text, {super.key, this.padding = const EdgeInsets.only(top: 32, bottom: 12)});

  @override
  Widget build(BuildContext context) => Padding(
        padding: padding,
        child: Text(
          text.toUpperCase(),
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.9, color: context.colors.textTertiary),
        ),
      );
}

/// Plain text tabs with an underline on the active one.
class TextTabs extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const TextTabs({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < labels.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onChanged(i),
                  child: Container(
                    margin: const EdgeInsets.only(right: 24),
                    padding: const EdgeInsets.only(bottom: 10, top: 4),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: i == selected ? c.textPrimary : Colors.transparent, width: 2)),
                    ),
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                        color: i == selected ? c.textPrimary : c.textTertiary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const HairlineDivider(),
      ],
    );
  }
}

/// Compact segmented switch (theme, language, grouping...).
class AppSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onChanged;
  const AppSegmented({super.key, required this.labels, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final selectedFill = dark ? Color.lerp(c.outline, c.textPrimary, 0.14)! : c.surfaceRaised;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(color: c.outline, borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onChanged(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: i == selected ? selectedFill : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  labels[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == selected ? FontWeight.w600 : FontWeight.w500,
                    color: i == selected ? c.textPrimary : c.textSecondary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Single-choice pill used for quick filters (asset class, year...). The
/// chosen one is solid ink; the rest are outlines.
class ChoicePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const ChoicePill({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? c.textPrimary : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: selected ? c.textPrimary : c.outline),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: selected ? c.surface : c.textSecondary)),
      ),
    );
  }
}
