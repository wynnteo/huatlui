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
  /// **'Dashboard'**
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
  /// **'Transactions'**
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

  /// No description provided for @editHoldingTitle.
  ///
  /// In en, this message translates to:
  /// **'Update {symbol}'**
  String editHoldingTitle(String symbol);

  /// No description provided for @currentPriceLabel.
  ///
  /// In en, this message translates to:
  /// **'Current price ({currency})'**
  String currentPriceLabel(String currency);

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
