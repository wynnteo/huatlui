// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'HuatLui';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navHoldings => 'Holdings';

  @override
  String get navAllocation => 'Allocation';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navMore => 'More';

  @override
  String get totalReturn => 'Total Return';

  @override
  String get capitalGain => 'Capital Gain';

  @override
  String get dividendIncome => 'Dividend Income';

  @override
  String get portfolioValue => 'Portfolio Value';

  @override
  String get totalInvested => 'Total Invested';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get dashboardEmptyTitle => 'No investments yet';

  @override
  String get dashboardEmptyBody =>
      'Add your first buy, or load sample data to see how HuatLui works.';

  @override
  String get loadDemoData => 'Load sample data';

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get clearAllDataConfirm =>
      'This permanently deletes every account, holding, transaction and dividend on this device.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteEntryTitle => 'Delete this entry?';

  @override
  String get holdingsEmpty => 'No open positions.';

  @override
  String get transactionsEmpty => 'No transactions yet.';

  @override
  String get allocationEmpty => 'Nothing to allocate yet.';

  @override
  String get buy => 'Buy';

  @override
  String get sell => 'Sell';

  @override
  String get dividend => 'Dividend';

  @override
  String get addTransaction => 'Add transaction';

  @override
  String get addDividend => 'Add dividend';

  @override
  String get groupAssetClass => 'Asset class';

  @override
  String get groupAccount => 'Account';

  @override
  String get groupCurrency => 'Currency';

  @override
  String get groupHolding => 'Holding';

  @override
  String get assetClassStock => 'Stock';

  @override
  String get assetClassEtf => 'ETF';

  @override
  String get assetClassUnitTrust => 'Unit trust';

  @override
  String get assetClassReit => 'REIT';

  @override
  String get assetClassBond => 'Bond';

  @override
  String get assetClassCash => 'Cash';

  @override
  String get assetClassOther => 'Other';

  @override
  String get currentAllocation => 'Current';

  @override
  String get targetAllocation => 'Target';

  @override
  String targetPct(String pct) {
    return 'Target $pct%';
  }

  @override
  String get noTargetSet => 'No target set';

  @override
  String get concentrationRiskTitle => 'Concentration risk';

  @override
  String needAttention(String count) {
    return '$count to review';
  }

  @override
  String concentrationRiskOverTarget(
      String label, String current, String target) {
    return '$label is $current% of your portfolio, above your $target% target.';
  }

  @override
  String concentrationRiskUnderTarget(
      String label, String current, String target) {
    return '$label is $current% of your portfolio, below your $target% target.';
  }

  @override
  String concentrationRiskAbsolute(String label, String current) {
    return '$label is $current% of your portfolio. A single holding this large adds concentration risk.';
  }

  @override
  String get settingsBaseCurrency => 'Base currency';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsThemeLight => 'Light';

  @override
  String get settingsThemeDark => 'Dark';

  @override
  String get settingsThemeSystem => 'Match system';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsData => 'Data';

  @override
  String shownInBaseCurrency(String currency) {
    return 'Shown in $currency';
  }

  @override
  String get addEntry => 'Add entry';

  @override
  String get fieldAccount => 'Account';

  @override
  String get newAccountOption => 'New account…';

  @override
  String get fieldNewAccountName => 'New account name';

  @override
  String get createAccountHint => 'e.g. Tiger Brokers';

  @override
  String get fieldSymbol => 'Symbol';

  @override
  String get symbolHint => 'e.g. AAPL, D05.SI';

  @override
  String get fieldName => 'Name (optional)';

  @override
  String get fieldAssetClass => 'Asset class';

  @override
  String get fieldCurrency => 'Currency';

  @override
  String get fieldDate => 'Date';

  @override
  String get fieldQuantity => 'Quantity';

  @override
  String get fieldPrice => 'Price per unit';

  @override
  String get fieldFees => 'Fees (commission etc.)';

  @override
  String get fieldGrossAmount => 'Dividend amount (before tax)';

  @override
  String get fieldWithholdingTax => 'Withholding tax';

  @override
  String get fieldFxRate => 'FX rate';

  @override
  String fxRateHelp(String currency, String base) {
    return '1 $currency = ? $base. Pre-filled with today\'s built-in rate; change it to the rate on the trade date for an exact cost.';
  }

  @override
  String get fieldNotes => 'Notes (optional)';

  @override
  String get save => 'Save';

  @override
  String get pickHoldingHint => 'Pick an existing holding';

  @override
  String get errAccountRequired =>
      'Choose an account or enter a new account name.';

  @override
  String get errSymbolRequired => 'Enter a symbol.';

  @override
  String errNumber(String field) {
    return 'Enter a valid number for $field.';
  }

  @override
  String errOnlyHold(String qty, String symbol) {
    return 'You only hold $qty of $symbol in this account.';
  }

  @override
  String get errDividendNeedsHolding =>
      'To record a dividend, pick a holding you already own.';

  @override
  String get errFxRate => 'Enter a valid FX rate.';

  @override
  String editHoldingTitle(String symbol) {
    return 'Update $symbol';
  }

  @override
  String currentPriceLabel(String currency) {
    return 'Current price ($currency)';
  }

  @override
  String get targetPctLabel => 'Target % of portfolio (blank = none)';

  @override
  String get holdingsTapHint => 'Tap a holding to update its price or target.';

  @override
  String get importCsv => 'Import from CSV';

  @override
  String get copyCsvTemplate => 'Copy CSV template';

  @override
  String get templateCopied =>
      'Template copied. Paste it into Excel or Google Sheets.';

  @override
  String get importPreviewTitle => 'Ready to import';

  @override
  String importSummary(String trades, String dividends, String accounts) {
    return '$trades trades, $dividends dividends, $accounts new accounts';
  }

  @override
  String importSkipped(String count) {
    return '$count duplicates skipped';
  }

  @override
  String importErrors(String count) {
    return '$count rows have problems and will be skipped:';
  }

  @override
  String get importNothing => 'Nothing to import.';

  @override
  String get importConfirm => 'Import';

  @override
  String get importDone => 'Import finished.';

  @override
  String importFailed(String reason) {
    return 'Couldn\'t read that file: $reason';
  }
}
