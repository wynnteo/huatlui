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
  String get navDashboard => 'Overview';

  @override
  String get navHoldings => 'Holdings';

  @override
  String get navAllocation => 'Allocation';

  @override
  String get navTransactions => 'Activity';

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
  String get dashboardEmptyBody => 'Add your first buy, or load sample data to see how HuatLui works.';

  @override
  String get loadDemoData => 'Load sample data';

  @override
  String get clearAllData => 'Clear all data';

  @override
  String get clearAllDataConfirm => 'This permanently deletes every account, holding, transaction and dividend on this device.';

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
  String concentrationRiskOverTarget(String label, String current, String target) {
    return '$label is $current% of your portfolio, above your $target% target.';
  }

  @override
  String concentrationRiskUnderTarget(String label, String current, String target) {
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
  String get errAccountRequired => 'Choose an account or enter a new account name.';

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
  String get errDividendNeedsHolding => 'To record a dividend, pick a holding you already own.';

  @override
  String get errFxRate => 'Enter a valid FX rate.';

  @override
  String get targetPctLabel => 'Target % of portfolio (blank = none)';

  @override
  String get holdingsTapHint => 'Tap a holding to update its price or target.';

  @override
  String get importCsv => 'Import from CSV';

  @override
  String get copyCsvTemplate => 'Copy CSV template';

  @override
  String get templateCopied => 'Template copied. Paste it into Excel or Google Sheets.';

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

  @override
  String get navInsights => 'Insights';

  @override
  String get navSettings => 'Settings';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsRegion => 'Region';

  @override
  String get settingsThemeAuto => 'Auto';

  @override
  String get insightsHighlights => 'Highlights';

  @override
  String get insightsMore => 'More insights';

  @override
  String get insightsEmpty => 'Add a few transactions to see insights.';

  @override
  String get tabPerformance => 'Performance';

  @override
  String get tabIncome => 'Income';

  @override
  String get returnByHolding => 'Capital gain by holding';

  @override
  String get investedByMonth => 'Invested by month';

  @override
  String get dividendsByMonth => 'Dividends by month';

  @override
  String get byHolding => 'By holding';

  @override
  String get breakdown => 'Breakdown';

  @override
  String get unrealisedGain => 'Unrealised gain';

  @override
  String get realisedGain => 'Realised gain';

  @override
  String get feesPaid => 'Fees paid';

  @override
  String get holdingsInProfit => 'Holdings in profit';

  @override
  String winRateValue(String count, String total) {
    return '$count of $total';
  }

  @override
  String get dividendsTtm => 'Last 12 months';

  @override
  String get yieldOnCost => 'Yield on cost';

  @override
  String get incomeEmpty => 'No dividends recorded yet.';

  @override
  String insightTopContributor(String symbol, String amount, String share) {
    return '$symbol contributes most to your capital gain: $amount, $share% of total gains.';
  }

  @override
  String insightBiggestDrag(String symbol, String amount) {
    return '$symbol is your biggest drag on capital gain: $amount.';
  }

  @override
  String insightConcentration(String count, String pct) {
    return 'Your top $count holdings make up $pct% of the portfolio.';
  }

  @override
  String insightDividends(String amount, String yieldPct) {
    return 'Dividends so far this year came to $amount, a $yieldPct% yield on cost.';
  }

  @override
  String insightCurrency(String pct, String currency) {
    return '$pct% of your portfolio is held in $currency.';
  }

  @override
  String insightFees(String amount, String pct) {
    return 'You have paid $amount in fees, $pct% of the amount you have invested.';
  }

  @override
  String get rangeAll => 'All';

  @override
  String get chartValueVsCost => 'Value vs cost';

  @override
  String get chartValue => 'Value';

  @override
  String get chartCost => 'Cost';

  @override
  String get chartNote => 'Past values use today\'s exchange rates. Unit trusts fill in as you refresh prices.';

  @override
  String get chartNeedsData => 'Not enough history yet. Pull down on Overview or Holdings to refresh prices.';

  @override
  String get chartTotal => 'Total';

  @override
  String get dividendsYoY => 'This year vs last year';

  @override
  String get incomeSources => 'Income sources';

  @override
  String get othersLabel => 'Other';

  @override
  String pricesUpdated(String when) {
    return 'Prices updated $when';
  }

  @override
  String get pricesNever => 'Prices not updated yet';

  @override
  String get pricesUpdating => 'Updating prices…';

  @override
  String pricesRefreshResult(String updated, String failed) {
    return '$updated updated, $failed failed';
  }

  @override
  String get settingsPrices => 'Prices';

  @override
  String get refreshPrices => 'Refresh prices';

  @override
  String get assetClassCrypto => 'Crypto';

  @override
  String get exportCsv => 'Export CSV';

  @override
  String get exportEmpty => 'Nothing to export yet.';

  @override
  String exportDone(String count) {
    return 'Exported $count rows.';
  }

  @override
  String get exportCopied => 'No file dialog available. The CSV was copied to the clipboard instead.';

  @override
  String get filterDate => 'Date';

  @override
  String get filterType => 'Type';

  @override
  String get filterBroker => 'Broker';

  @override
  String get filterClass => 'Asset class';

  @override
  String get filterClear => 'Clear';

  @override
  String get rangeAllTime => 'All time';

  @override
  String get rangeThisMonth => 'This month';

  @override
  String get rangeLast30 => 'Last 30 days';

  @override
  String get rangeThisYear => 'This year';

  @override
  String get rangeLastYear => 'Last year';

  @override
  String get rangeCustom => 'Custom range…';

  @override
  String get filterNoMatch => 'No transactions match these filters.';

  @override
  String filterBrokersCount(String count) {
    return '$count brokers';
  }

  @override
  String filterClassesCount(String count) {
    return '$count classes';
  }

  @override
  String filterTransactions(String count) {
    return '$count transactions';
  }

  @override
  String get summaryBought => 'Bought';

  @override
  String get summarySold => 'Sold';

  @override
  String get priceNotUpdated => 'Price not updated';

  @override
  String priceAsOf(String date) {
    return 'Price as of $date';
  }

  @override
  String pricesFailedList(String symbols) {
    return 'Could not price: $symbols';
  }

  @override
  String get lockedTitle => 'HuatLui is locked';

  @override
  String get unlockButton => 'Unlock';

  @override
  String get unlockReason => 'Unlock HuatLui to view your portfolio';

  @override
  String get settingsSecurity => 'Security';

  @override
  String get settingsLock => 'Biometric unlock';

  @override
  String get settingsLockHelp => 'Uses your fingerprint, face, or the phone’s screen lock. HuatLui locks again after 30 seconds in the background.';

  @override
  String get lockUnavailable => 'Set up a fingerprint, face or screen lock on this phone first.';

  @override
  String get filterAll => 'All';

  @override
  String get byAssetClass => 'By asset class';

  @override
  String incomeYearLabel(String year) {
    return '$year dividends';
  }

  @override
  String incomeLastYear(String amount) {
    return 'Last year $amount';
  }

  @override
  String incomeEmptyYear(String year) {
    return 'No dividends in $year.';
  }

  @override
  String get chartHowLink => 'How is this calculated?';

  @override
  String get chartHowTitle => 'How value and cost are calculated';

  @override
  String get chartHowCostTitle => 'Cost (dashed line)';

  @override
  String get chartHowCostBody => 'What you paid for the holdings you still own. Each buy adds quantity × price plus fees, converted at that trade’s own exchange rate. A sale removes the same share of the cost (average-cost method), so fully sold positions drop out.';

  @override
  String get chartHowValueTitle => 'Value (solid line)';

  @override
  String get chartHowValueBody => 'For each day: the units you held that day (rebuilt from your transactions) × that day’s closing price, converted at today’s exchange rate. Weekends and holidays reuse the last close. Unit trusts have no price history, so they step between your trade prices and the prices fetched since you started refreshing.';

  @override
  String get chartHowGapTitle => 'The gap between them';

  @override
  String get chartHowGapBody => 'That is your unrealised gain or loss. Dividends and gains already locked in by selling are not in this chart; see Breakdown below and the Income tab.';

  @override
  String get settingsAbout => 'About';

  @override
  String get aboutVersion => 'Version';

  @override
  String latestPrice(String price) {
    return 'Latest $price';
  }

  @override
  String get editEntry => 'Edit entry';

  @override
  String get errBreaksHoldings => 'That would leave a later sale larger than the units you held. Change or delete the sale first.';

  @override
  String get holdingDetails => 'Details';

  @override
  String get detailMarketValue => 'Market value';

  @override
  String get detailUnits => 'Units';

  @override
  String get detailAvgPrice => 'Average price';

  @override
  String get detailLatestPrice => 'Latest price';

  @override
  String get detailCost => 'Cost';

  @override
  String get detailDividends => 'Dividends collected';

  @override
  String get detailBroker => 'Broker';

  @override
  String get detailTarget => 'Target weight';

  @override
  String get detailNotSet => 'Not set';

  @override
  String get detailTransactions => 'Transactions';

  @override
  String get detailEmpty => 'No transactions for this holding.';

  @override
  String get fxSection => 'Exchange rates';

  @override
  String get fxSource => 'FX data source';

  @override
  String get fxDaily => 'Frankfurter (daily)';

  @override
  String get fxAsOf => 'FX rates as of';

  @override
  String get fxCached => ' (cached)';

  @override
  String get fxIndicative => 'Indicative only';

  @override
  String get fxRefresh => 'Refresh exchange rates';

  @override
  String get fxRefreshing => 'Updating…';

  @override
  String get fxUpdated => 'FX rates updated';

  @override
  String get fxRefreshFailed => 'FX update failed. Cached rates retained.';

  @override
  String get fxFailedCached => 'FX: last refresh failed; showing cached values.';

  @override
  String get fxFailedIndicative => 'FX: last refresh failed; showing indicative values.';

  @override
  String get fxDashboardIndicative => 'FX: indicative offline rates (not current market data)';

  @override
  String get fxDashboardCached => 'FX: cached rates as of';

  @override
  String get fxDashboardReference => 'FX: daily reference rates as of';

  @override
  String get pricesSomeStale => 'Some prices need updating';

  @override
  String get backupSave => 'Save full backup (JSON)';

  @override
  String get backupRestore => 'Restore full backup (JSON)';

  @override
  String get backupSaveDialog => 'Save HuatLui backup';

  @override
  String get backupSaved => 'Backup saved. Keep it in a secure location.';

  @override
  String get backupSaveFailed => 'Backup failed:';

  @override
  String get backupRestoreTitle => 'Restore portfolio backup?';

  @override
  String get backupReplaceWarning => 'This will REPLACE your current portfolio data on this device.';

  @override
  String get backupAccounts => 'Accounts';

  @override
  String get backupHoldings => 'Holdings';

  @override
  String get backupTrades => 'Trades';

  @override
  String get backupDividends => 'Dividends';

  @override
  String get backupRestoreWarning => 'Create and save a backup of your current portfolio first. Device lock preferences will not be changed.';

  @override
  String get backupReplace => 'Replace & restore';

  @override
  String get backupRestored => 'Portfolio backup restored successfully.';

  @override
  String get backupRestoreFailed => 'Restore failed:';
}
