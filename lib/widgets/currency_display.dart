import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';

/// Formatting rule for the whole app, per the architecture doc:
///
/// - **Per-item** (a holding row, a transaction row, holding detail):
///   always show the amount in its **own original currency**. Never
///   converted. Use [CurrencyText.original] for these — a USD holding
///   just reads "US$1,500.00", full stop.
///
/// - **Aggregates** (Dashboard totals, Asset Allocation %, Total Return):
///   always converted to the user's **base currency**, because you can't
///   sum USD+SGD+MYR into one meaningful number otherwise. Use
///   [CurrencyText.base] for these, and pair the section with a small
///   "Shown in {currency}" caption (see [BaseCurrencyNote]) so it's clear
///   a conversion happened.
class CurrencyText extends StatelessWidget {
  final double amount;
  final String currencyCode;
  final TextStyle? style;
  final TextAlign textAlign;

  const CurrencyText.original(
    this.amount,
    this.currencyCode, {
    super.key,
    this.style,
    this.textAlign = TextAlign.end,
  });

  const CurrencyText.base(
    this.amount,
    this.currencyCode, {
    super.key,
    this.style,
    this.textAlign = TextAlign.end,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(
      formatAmount(amount, currencyCode),
      textAlign: textAlign,
      style: style ?? TextStyle(fontWeight: FontWeight.w600, color: colors.textPrimary, fontSize: 15),
    );
  }

  static String formatAmount(double amount, String currencyCode) {
    final symbol = _symbols[currencyCode] ?? '$currencyCode ';
    final sign = amount < 0 ? '-' : '';
    final formatted = NumberFormat('#,##0.00').format(amount.abs());
    return '$sign$symbol$formatted';
  }

  /// "+S$1,200.00" / "-S$300.00" - for gains, losses and returns.
  static String formatSigned(double amount, String currencyCode) {
    final body = formatAmount(amount.abs(), currencyCode);
    if (amount > 0) return '+$body';
    if (amount < 0) return '-$body';
    return body;
  }

  static const _symbols = {
    'SGD': 'S\$',
    'USD': 'US\$',
    'MYR': 'RM',
    'HKD': 'HK\$',
    'CNY': '¥',
    'GBP': '£',
    'EUR': '€',
  };
}

/// Small caption to drop under any aggregate section, so it's always
/// visually clear that number is a conversion, not the one true figure.
class BaseCurrencyNote extends StatelessWidget {
  final String label; // pass AppLocalizations.of(context)!.shownInBaseCurrency(code)
  const BaseCurrencyNote(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>()!;
    return Text(label, style: TextStyle(fontSize: 11, color: colors.textTertiary));
  }
}
