import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'HuatLui'**
  String get appTitle;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get navDashboard;

  /// No description provided for @navHoldings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get navHoldings;

  /// No description provided for @navAllocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get navAllocation;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Activity'**
  String get navTransactions;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @totalReturn.
  ///
  /// In en, this message translates to:
  /// **'Total Return'**
  String get totalReturn;

  /// No description provided for @capitalGain.
  ///
  /// In en, this message translates to:
  /// **'Capital Gain'**
  String get capitalGain;

  /// No description provided for @dividendIncome.
  ///
  /// In en, this message translates to:
  /// **'Dividend Income'**
  String get dividendIncome;

  /// No description provided for @portfolioValue.
  ///
  /// In en, this message translates to:
  /// **'Portfolio Value'**
  String get portfolioValue;

  /// No description provided for @totalInvested.
  ///
  /// In en, this message translates to:
  /// **'Total Invested'**
  String get totalInvested;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No investments yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first buy, or load sample data to see how HuatLui works.'**
  String get dashboardEmptyBody;

  /// No description provided for @loadDemoData.
  ///
  /// In en, this message translates to:
  /// **'Load sample data'**
  String get loadDemoData;

  /// No description provided for @clearAllData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get clearAllData;

  /// No description provided for @clearAllDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes every account, holding, transaction and dividend on this device.'**
  String get clearAllDataConfirm;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteEntryTitle;

  /// No description provided for @holdingsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No open positions.'**
  String get holdingsEmpty;

  /// No description provided for @transactionsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet.'**
  String get transactionsEmpty;

  /// No description provided for @allocationEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to allocate yet.'**
  String get allocationEmpty;

  /// No description provided for @buy.
  ///
  /// In en, this message translates to:
  /// **'Buy'**
  String get buy;

  /// No description provided for @sell.
  ///
  /// In en, this message translates to:
  /// **'Sell'**
  String get sell;

  /// No description provided for @dividend.
  ///
  /// In en, this message translates to:
  /// **'Dividend'**
  String get dividend;

  /// No description provided for @addTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get addTransaction;

  /// No description provided for @addDividend.
  ///
  /// In en, this message translates to:
  /// **'Add dividend'**
  String get addDividend;

  /// No description provided for @groupAssetClass.
  ///
  /// In en, this message translates to:
  /// **'Asset class'**
  String get groupAssetClass;

  /// No description provided for @groupAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get groupAccount;

  /// No description provided for @groupCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get groupCurrency;

  /// No description provided for @groupHolding.
  ///
  /// In en, this message translates to:
  /// **'Holding'**
  String get groupHolding;

  /// No description provided for @assetClassStock.
  ///
  /// In en, this message translates to:
  /// **'Stock'**
  String get assetClassStock;

  /// No description provided for @assetClassEtf.
  ///
  /// In en, this message translates to:
  /// **'ETF'**
  String get assetClassEtf;

  /// No description provided for @assetClassUnitTrust.
  ///
  /// In en, this message translates to:
  /// **'Unit trust'**
  String get assetClassUnitTrust;

  /// No description provided for @assetClassReit.
  ///
  /// In en, this message translates to:
  /// **'REIT'**
  String get assetClassReit;

  /// No description provided for @assetClassBond.
  ///
  /// In en, this message translates to:
  /// **'Bond'**
  String get assetClassBond;

  /// No description provided for @assetClassCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get assetClassCash;

  /// No description provided for @assetClassOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get assetClassOther;

  /// No description provided for @currentAllocation.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get currentAllocation;

  /// No description provided for @targetAllocation.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get targetAllocation;

  /// No description provided for @targetPct.
  ///
  /// In en, this message translates to:
  /// **'Target {pct}%'**
  String targetPct(String pct);

  /// No description provided for @noTargetSet.
  ///
  /// In en, this message translates to:
  /// **'No target set'**
  String get noTargetSet;

  /// No description provided for @concentrationRiskTitle.
  ///
  /// In en, this message translates to:
  /// **'Concentration risk'**
  String get concentrationRiskTitle;

  /// No description provided for @needAttention.
  ///
  /// In en, this message translates to:
  /// **'{count} to review'**
  String needAttention(String count);

  /// No description provided for @concentrationRiskOverTarget.
  ///
  /// In en, this message translates to:
  /// **'{label} is {current}% of your portfolio, above your {target}% target.'**
  String concentrationRiskOverTarget(
      String label, String current, String target);

  /// No description provided for @concentrationRiskUnderTarget.
  ///
  /// In en, this message translates to:
  /// **'{label} is {current}% of your portfolio, below your {target}% target.'**
  String concentrationRiskUnderTarget(
      String label, String current, String target);

  /// No description provided for @concentrationRiskAbsolute.
  ///
  /// In en, this message translates to:
  /// **'{label} is {current}% of your portfolio. A single holding this large adds concentration risk.'**
  String concentrationRiskAbsolute(String label, String current);

  /// No description provided for @settingsBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Base currency'**
  String get settingsBaseCurrency;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsThemeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get settingsThemeLight;

  /// No description provided for @settingsThemeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get settingsThemeDark;

  /// No description provided for @settingsThemeSystem.
  ///
  /// In en, this message translates to:
  /// **'Match system'**
  String get settingsThemeSystem;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @shownInBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Shown in {currency}'**
  String shownInBaseCurrency(String currency);

  /// No description provided for @addEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get addEntry;

  /// No description provided for @fieldAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get fieldAccount;

  /// No description provided for @newAccountOption.
  ///
  /// In en, this message translates to:
  /// **'New account…'**
  String get newAccountOption;

  /// No description provided for @fieldNewAccountName.
  ///
  /// In en, this message translates to:
  /// **'New account name'**
  String get fieldNewAccountName;

  /// No description provided for @createAccountHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Tiger Brokers'**
  String get createAccountHint;

  /// No description provided for @fieldSymbol.
  ///
  /// In en, this message translates to:
  /// **'Symbol'**
  String get fieldSymbol;

  /// No description provided for @symbolHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. AAPL, D05.SI'**
  String get symbolHint;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Name (optional)'**
  String get fieldName;

  /// No description provided for @fieldAssetClass.
  ///
  /// In en, this message translates to:
  /// **'Asset class'**
  String get fieldAssetClass;

  /// No description provided for @fieldCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get fieldCurrency;

  /// No description provided for @fieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fieldDate;

  /// No description provided for @fieldQuantity.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get fieldQuantity;

  /// No description provided for @fieldPrice.
  ///
  /// In en, this message translates to:
  /// **'Price per unit'**
  String get fieldPrice;

  /// No description provided for @fieldFees.
  ///
  /// In en, this message translates to:
  /// **'Fees (commission etc.)'**
  String get fieldFees;

  /// No description provided for @fieldGrossAmount.
  ///
  /// In en, this message translates to:
  /// **'Dividend amount (before tax)'**
  String get fieldGrossAmount;

  /// No description provided for @fieldWithholdingTax.
  ///
  /// In en, this message translates to:
  /// **'Withholding tax'**
  String get fieldWithholdingTax;

  /// No description provided for @fieldFxRate.
  ///
  /// In en, this message translates to:
  /// **'FX rate'**
  String get fieldFxRate;

  /// No description provided for @fxRateHelp.
  ///
  /// In en, this message translates to:
  /// **'1 {currency} = ? {base}. Pre-filled with today\'s built-in rate; change it to the rate on the trade date for an exact cost.'**
  String fxRateHelp(String currency, String base);

  /// No description provided for @fieldNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes (optional)'**
  String get fieldNotes;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @pickHoldingHint.
  ///
  /// In en, this message translates to:
  /// **'Pick an existing holding'**
  String get pickHoldingHint;

  /// No description provided for @errAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Choose an account or enter a new account name.'**
  String get errAccountRequired;

  /// No description provided for @errSymbolRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a symbol.'**
  String get errSymbolRequired;

  /// No description provided for @errNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number for {field}.'**
  String errNumber(String field);

  /// No description provided for @errOnlyHold.
  ///
  /// In en, this message translates to:
  /// **'You only hold {qty} of {symbol} in this account.'**
  String errOnlyHold(String qty, String symbol);

  /// No description provided for @errDividendNeedsHolding.
  ///
  /// In en, this message translates to:
  /// **'To record a dividend, pick a holding you already own.'**
  String get errDividendNeedsHolding;

  /// No description provided for @errFxRate.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid FX rate.'**
  String get errFxRate;

  /// No description provided for @targetPctLabel.
  ///
  /// In en, this message translates to:
  /// **'Target % of portfolio (blank = none)'**
  String get targetPctLabel;

  /// No description provided for @holdingsTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a holding to update its price or target.'**
  String get holdingsTapHint;

  /// No description provided for @importCsv.
  ///
  /// In en, this message translates to:
  /// **'Import from CSV'**
  String get importCsv;

  /// No description provided for @copyCsvTemplate.
  ///
  /// In en, this message translates to:
  /// **'Copy CSV template'**
  String get copyCsvTemplate;

  /// No description provided for @templateCopied.
  ///
  /// In en, this message translates to:
  /// **'Template copied. Paste it into Excel or Google Sheets.'**
  String get templateCopied;

  /// No description provided for @importPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to import'**
  String get importPreviewTitle;

  /// No description provided for @importSummary.
  ///
  /// In en, this message translates to:
  /// **'{trades} trades, {dividends} dividends, {accounts} new accounts'**
  String importSummary(String trades, String dividends, String accounts);

  /// No description provided for @importSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count} duplicates skipped'**
  String importSkipped(String count);

  /// No description provided for @importErrors.
  ///
  /// In en, this message translates to:
  /// **'{count} rows have problems and will be skipped:'**
  String importErrors(String count);

  /// No description provided for @importNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to import.'**
  String get importNothing;

  /// No description provided for @importConfirm.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get importConfirm;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Import finished.'**
  String get importDone;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read that file: {reason}'**
  String importFailed(String reason);

  /// No description provided for @navInsights.
  ///
  /// In en, this message translates to:
  /// **'Insights'**
  String get navInsights;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get settingsRegion;

  /// No description provided for @settingsThemeAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsThemeAuto;

  /// No description provided for @insightsHighlights.
  ///
  /// In en, this message translates to:
  /// **'Highlights'**
  String get insightsHighlights;

  /// No description provided for @insightsMore.
  ///
  /// In en, this message translates to:
  /// **'More insights'**
  String get insightsMore;

  /// No description provided for @insightsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a few transactions to see insights.'**
  String get insightsEmpty;

  /// No description provided for @tabPerformance.
  ///
  /// In en, this message translates to:
  /// **'Performance'**
  String get tabPerformance;

  /// No description provided for @tabIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get tabIncome;

  /// No description provided for @returnByHolding.
  ///
  /// In en, this message translates to:
  /// **'Capital gain by holding'**
  String get returnByHolding;

  /// No description provided for @investedByMonth.
  ///
  /// In en, this message translates to:
  /// **'Invested by month'**
  String get investedByMonth;

  /// No description provided for @dividendsByMonth.
  ///
  /// In en, this message translates to:
  /// **'Dividends by month'**
  String get dividendsByMonth;

  /// No description provided for @byHolding.
  ///
  /// In en, this message translates to:
  /// **'By holding'**
  String get byHolding;

  /// No description provided for @breakdown.
  ///
  /// In en, this message translates to:
  /// **'Breakdown'**
  String get breakdown;

  /// No description provided for @unrealisedGain.
  ///
  /// In en, this message translates to:
  /// **'Unrealised gain'**
  String get unrealisedGain;

  /// No description provided for @realisedGain.
  ///
  /// In en, this message translates to:
  /// **'Realised gain'**
  String get realisedGain;

  /// No description provided for @feesPaid.
  ///
  /// In en, this message translates to:
  /// **'Fees paid'**
  String get feesPaid;

  /// No description provided for @holdingsInProfit.
  ///
  /// In en, this message translates to:
  /// **'Holdings in profit'**
  String get holdingsInProfit;

  /// No description provided for @winRateValue.
  ///
  /// In en, this message translates to:
  /// **'{count} of {total}'**
  String winRateValue(String count, String total);

  /// No description provided for @dividendsTtm.
  ///
  /// In en, this message translates to:
  /// **'Last 12 months'**
  String get dividendsTtm;

  /// No description provided for @yieldOnCost.
  ///
  /// In en, this message translates to:
  /// **'Yield on cost'**
  String get yieldOnCost;

  /// No description provided for @incomeEmpty.
  ///
  /// In en, this message translates to:
  /// **'No dividends recorded yet.'**
  String get incomeEmpty;

  /// No description provided for @insightTopContributor.
  ///
  /// In en, this message translates to:
  /// **'{symbol} contributes most to your capital gain: {amount}, {share}% of total gains.'**
  String insightTopContributor(String symbol, String amount, String share);

  /// No description provided for @insightBiggestDrag.
  ///
  /// In en, this message translates to:
  /// **'{symbol} is your biggest drag on capital gain: {amount}.'**
  String insightBiggestDrag(String symbol, String amount);

  /// No description provided for @insightConcentration.
  ///
  /// In en, this message translates to:
  /// **'Your top {count} holdings make up {pct}% of the portfolio.'**
  String insightConcentration(String count, String pct);

  /// No description provided for @insightDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends so far this year came to {amount}, a {yieldPct}% yield on cost.'**
  String insightDividends(String amount, String yieldPct);

  /// No description provided for @insightCurrency.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of your portfolio is held in {currency}.'**
  String insightCurrency(String pct, String currency);

  /// No description provided for @insightFees.
  ///
  /// In en, this message translates to:
  /// **'You have paid {amount} in fees, {pct}% of the amount you have invested.'**
  String insightFees(String amount, String pct);

  /// No description provided for @rangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get rangeAll;

  /// No description provided for @chartValueVsCost.
  ///
  /// In en, this message translates to:
  /// **'Value vs cost'**
  String get chartValueVsCost;

  /// No description provided for @chartValue.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get chartValue;

  /// No description provided for @chartCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get chartCost;

  /// No description provided for @chartNote.
  ///
  /// In en, this message translates to:
  /// **'Past values use today\'s exchange rates. Unit trusts fill in as you refresh prices.'**
  String get chartNote;

  /// No description provided for @chartNeedsData.
  ///
  /// In en, this message translates to:
  /// **'Not enough history yet. Pull down on Overview or Holdings to refresh prices.'**
  String get chartNeedsData;

  /// No description provided for @chartTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get chartTotal;

  /// No description provided for @dividendsYoY.
  ///
  /// In en, this message translates to:
  /// **'This year vs last year'**
  String get dividendsYoY;

  /// No description provided for @incomeSources.
  ///
  /// In en, this message translates to:
  /// **'Income sources'**
  String get incomeSources;

  /// No description provided for @othersLabel.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get othersLabel;

  /// No description provided for @pricesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Prices updated {when}'**
  String pricesUpdated(String when);

  /// No description provided for @pricesNever.
  ///
  /// In en, this message translates to:
  /// **'Prices not updated yet'**
  String get pricesNever;

  /// No description provided for @pricesUpdating.
  ///
  /// In en, this message translates to:
  /// **'Updating prices…'**
  String get pricesUpdating;

  /// No description provided for @pricesRefreshResult.
  ///
  /// In en, this message translates to:
  /// **'{updated} updated, {failed} failed'**
  String pricesRefreshResult(String updated, String failed);

  /// No description provided for @settingsPrices.
  ///
  /// In en, this message translates to:
  /// **'Prices'**
  String get settingsPrices;

  /// No description provided for @refreshPrices.
  ///
  /// In en, this message translates to:
  /// **'Refresh prices'**
  String get refreshPrices;

  /// No description provided for @assetClassCrypto.
  ///
  /// In en, this message translates to:
  /// **'Crypto'**
  String get assetClassCrypto;

  /// No description provided for @exportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get exportCsv;

  /// No description provided for @exportEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing to export yet.'**
  String get exportEmpty;

  /// No description provided for @exportDone.
  ///
  /// In en, this message translates to:
  /// **'Exported {count} rows.'**
  String exportDone(String count);

  /// No description provided for @exportCopied.
  ///
  /// In en, this message translates to:
  /// **'No file dialog available. The CSV was copied to the clipboard instead.'**
  String get exportCopied;

  /// No description provided for @filterDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get filterDate;

  /// No description provided for @filterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get filterType;

  /// No description provided for @filterBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get filterBroker;

  /// No description provided for @filterClass.
  ///
  /// In en, this message translates to:
  /// **'Asset class'**
  String get filterClass;

  /// No description provided for @filterClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get filterClear;

  /// No description provided for @rangeAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get rangeAllTime;

  /// No description provided for @rangeThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get rangeThisMonth;

  /// No description provided for @rangeLast30.
  ///
  /// In en, this message translates to:
  /// **'Last 30 days'**
  String get rangeLast30;

  /// No description provided for @rangeThisYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get rangeThisYear;

  /// No description provided for @rangeLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year'**
  String get rangeLastYear;

  /// No description provided for @rangeCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom range…'**
  String get rangeCustom;

  /// No description provided for @filterNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get filterNoMatch;

  /// No description provided for @filterBrokersCount.
  ///
  /// In en, this message translates to:
  /// **'{count} brokers'**
  String filterBrokersCount(String count);

  /// No description provided for @filterClassesCount.
  ///
  /// In en, this message translates to:
  /// **'{count} classes'**
  String filterClassesCount(String count);

  /// No description provided for @filterTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count} transactions'**
  String filterTransactions(String count);

  /// No description provided for @summaryBought.
  ///
  /// In en, this message translates to:
  /// **'Bought'**
  String get summaryBought;

  /// No description provided for @summarySold.
  ///
  /// In en, this message translates to:
  /// **'Sold'**
  String get summarySold;

  /// No description provided for @priceNotUpdated.
  ///
  /// In en, this message translates to:
  /// **'Price not updated'**
  String get priceNotUpdated;

  /// No description provided for @priceAsOf.
  ///
  /// In en, this message translates to:
  /// **'Price as of {date}'**
  String priceAsOf(String date);

  /// No description provided for @pricesFailedList.
  ///
  /// In en, this message translates to:
  /// **'Could not price: {symbols}'**
  String pricesFailedList(String symbols);

  /// No description provided for @lockedTitle.
  ///
  /// In en, this message translates to:
  /// **'HuatLui is locked'**
  String get lockedTitle;

  /// No description provided for @unlockButton.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlockButton;

  /// No description provided for @unlockReason.
  ///
  /// In en, this message translates to:
  /// **'Unlock HuatLui to view your portfolio'**
  String get unlockReason;

  /// No description provided for @settingsSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSecurity;

  /// No description provided for @settingsLock.
  ///
  /// In en, this message translates to:
  /// **'Biometric unlock'**
  String get settingsLock;

  /// No description provided for @settingsLockHelp.
  ///
  /// In en, this message translates to:
  /// **'Uses your fingerprint, face, or the phone’s screen lock. HuatLui locks again after 30 seconds in the background.'**
  String get settingsLockHelp;

  /// No description provided for @lockUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Set up a fingerprint, face or screen lock on this phone first.'**
  String get lockUnavailable;

  /// No description provided for @filterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get filterAll;

  /// No description provided for @byAssetClass.
  ///
  /// In en, this message translates to:
  /// **'By asset class'**
  String get byAssetClass;

  /// No description provided for @incomeYearLabel.
  ///
  /// In en, this message translates to:
  /// **'{year} dividends'**
  String incomeYearLabel(String year);

  /// No description provided for @incomeLastYear.
  ///
  /// In en, this message translates to:
  /// **'Last year {amount}'**
  String incomeLastYear(String amount);

  /// No description provided for @incomeEmptyYear.
  ///
  /// In en, this message translates to:
  /// **'No dividends in {year}.'**
  String incomeEmptyYear(String year);

  /// No description provided for @chartHowLink.
  ///
  /// In en, this message translates to:
  /// **'How is this calculated?'**
  String get chartHowLink;

  /// No description provided for @chartHowTitle.
  ///
  /// In en, this message translates to:
  /// **'How value and cost are calculated'**
  String get chartHowTitle;

  /// No description provided for @chartHowCostTitle.
  ///
  /// In en, this message translates to:
  /// **'Cost (dashed line)'**
  String get chartHowCostTitle;

  /// No description provided for @chartHowCostBody.
  ///
  /// In en, this message translates to:
  /// **'What you paid for the holdings you still own. Each buy adds quantity × price plus fees, converted at that trade’s own exchange rate. A sale removes the same share of the cost (average-cost method), so fully sold positions drop out.'**
  String get chartHowCostBody;

  /// No description provided for @chartHowValueTitle.
  ///
  /// In en, this message translates to:
  /// **'Value (solid line)'**
  String get chartHowValueTitle;

  /// No description provided for @chartHowValueBody.
  ///
  /// In en, this message translates to:
  /// **'For each day: the units you held that day (rebuilt from your transactions) × that day’s closing price, converted at today’s exchange rate. Weekends and holidays reuse the last close. Unit trusts have no price history, so they step between your trade prices and the prices fetched since you started refreshing.'**
  String get chartHowValueBody;

  /// No description provided for @chartHowGapTitle.
  ///
  /// In en, this message translates to:
  /// **'The gap between them'**
  String get chartHowGapTitle;

  /// No description provided for @chartHowGapBody.
  ///
  /// In en, this message translates to:
  /// **'That is your unrealised gain or loss. Dividends and gains already locked in by selling are not in this chart; see Breakdown below and the Income tab.'**
  String get chartHowGapBody;

  /// No description provided for @settingsAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsAbout;

  /// No description provided for @aboutVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// No description provided for @latestPrice.
  ///
  /// In en, this message translates to:
  /// **'Latest {price}'**
  String latestPrice(String price);

  /// No description provided for @editEntry.
  ///
  /// In en, this message translates to:
  /// **'Edit entry'**
  String get editEntry;

  /// No description provided for @errBreaksHoldings.
  ///
  /// In en, this message translates to:
  /// **'That would leave a later sale larger than the units you held. Change or delete the sale first.'**
  String get errBreaksHoldings;

  /// No description provided for @holdingDetails.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get holdingDetails;

  /// No description provided for @detailMarketValue.
  ///
  /// In en, this message translates to:
  /// **'Market value'**
  String get detailMarketValue;

  /// No description provided for @detailUnits.
  ///
  /// In en, this message translates to:
  /// **'Units'**
  String get detailUnits;

  /// No description provided for @detailAvgPrice.
  ///
  /// In en, this message translates to:
  /// **'Average price'**
  String get detailAvgPrice;

  /// No description provided for @detailLatestPrice.
  ///
  /// In en, this message translates to:
  /// **'Latest price'**
  String get detailLatestPrice;

  /// No description provided for @detailCost.
  ///
  /// In en, this message translates to:
  /// **'Cost'**
  String get detailCost;

  /// No description provided for @detailDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends collected'**
  String get detailDividends;

  /// No description provided for @detailBroker.
  ///
  /// In en, this message translates to:
  /// **'Broker'**
  String get detailBroker;

  /// No description provided for @detailTarget.
  ///
  /// In en, this message translates to:
  /// **'Target weight'**
  String get detailTarget;

  /// No description provided for @detailNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get detailNotSet;

  /// No description provided for @detailTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get detailTransactions;

  /// No description provided for @detailEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions for this holding.'**
  String get detailEmpty;

  /// No description provided for @fxSection.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get fxSection;

  /// No description provided for @fxSource.
  ///
  /// In en, this message translates to:
  /// **'FX data source'**
  String get fxSource;

  /// No description provided for @fxDaily.
  ///
  /// In en, this message translates to:
  /// **'Frankfurter (daily)'**
  String get fxDaily;

  /// No description provided for @fxAsOf.
  ///
  /// In en, this message translates to:
  /// **'FX rates as of'**
  String get fxAsOf;

  /// No description provided for @fxCached.
  ///
  /// In en, this message translates to:
  /// **' (cached)'**
  String get fxCached;

  /// No description provided for @fxIndicative.
  ///
  /// In en, this message translates to:
  /// **'Indicative only'**
  String get fxIndicative;

  /// No description provided for @fxRefresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh exchange rates'**
  String get fxRefresh;

  /// No description provided for @fxRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Updating…'**
  String get fxRefreshing;

  /// No description provided for @fxUpdated.
  ///
  /// In en, this message translates to:
  /// **'FX rates updated'**
  String get fxUpdated;

  /// No description provided for @fxRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'FX update failed. Cached rates retained.'**
  String get fxRefreshFailed;

  /// No description provided for @fxFailedCached.
  ///
  /// In en, this message translates to:
  /// **'FX: last refresh failed; showing cached values.'**
  String get fxFailedCached;

  /// No description provided for @fxFailedIndicative.
  ///
  /// In en, this message translates to:
  /// **'FX: last refresh failed; showing indicative values.'**
  String get fxFailedIndicative;

  /// No description provided for @fxDashboardIndicative.
  ///
  /// In en, this message translates to:
  /// **'FX: indicative offline rates (not current market data)'**
  String get fxDashboardIndicative;

  /// No description provided for @fxDashboardCached.
  ///
  /// In en, this message translates to:
  /// **'FX: cached rates as of'**
  String get fxDashboardCached;

  /// No description provided for @fxDashboardReference.
  ///
  /// In en, this message translates to:
  /// **'FX: daily reference rates as of'**
  String get fxDashboardReference;

  /// No description provided for @pricesSomeStale.
  ///
  /// In en, this message translates to:
  /// **'Some prices need updating'**
  String get pricesSomeStale;

  /// No description provided for @backupSave.
  ///
  /// In en, this message translates to:
  /// **'Save full backup (JSON)'**
  String get backupSave;

  /// No description provided for @backupRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore full backup (JSON)'**
  String get backupRestore;

  /// No description provided for @backupSaveDialog.
  ///
  /// In en, this message translates to:
  /// **'Save HuatLui backup'**
  String get backupSaveDialog;

  /// No description provided for @backupSaved.
  ///
  /// In en, this message translates to:
  /// **'Backup saved. Keep it in a secure location.'**
  String get backupSaved;

  /// No description provided for @backupSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Backup failed:'**
  String get backupSaveFailed;

  /// No description provided for @backupRestoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Restore portfolio backup?'**
  String get backupRestoreTitle;

  /// No description provided for @backupReplaceWarning.
  ///
  /// In en, this message translates to:
  /// **'This will REPLACE your current portfolio data on this device.'**
  String get backupReplaceWarning;

  /// No description provided for @backupAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get backupAccounts;

  /// No description provided for @backupHoldings.
  ///
  /// In en, this message translates to:
  /// **'Holdings'**
  String get backupHoldings;

  /// No description provided for @backupTrades.
  ///
  /// In en, this message translates to:
  /// **'Trades'**
  String get backupTrades;

  /// No description provided for @backupDividends.
  ///
  /// In en, this message translates to:
  /// **'Dividends'**
  String get backupDividends;

  /// No description provided for @backupRestoreWarning.
  ///
  /// In en, this message translates to:
  /// **'Create and save a backup of your current portfolio first. Device lock preferences will not be changed.'**
  String get backupRestoreWarning;

  /// No description provided for @backupReplace.
  ///
  /// In en, this message translates to:
  /// **'Replace & restore'**
  String get backupReplace;

  /// No description provided for @backupRestored.
  ///
  /// In en, this message translates to:
  /// **'Portfolio backup restored successfully.'**
  String get backupRestored;

  /// No description provided for @backupRestoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Restore failed:'**
  String get backupRestoreFailed;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
