import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_da.dart';
import 'app_localizations_en.dart';

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

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
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
    Locale('da'),
    Locale('en'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'BetBook'**
  String get appName;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get actionDelete;

  /// No description provided for @actionEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get actionEdit;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get actionNext;

  /// No description provided for @actionBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get actionBack;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get actionConfirm;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @siteDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'{name} deleted'**
  String siteDeletedSnack(String name);

  /// No description provided for @txDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txDeletedSnack;

  /// No description provided for @rateDeletedSnack.
  ///
  /// In en, this message translates to:
  /// **'{code} rate removed'**
  String rateDeletedSnack(String code);

  /// No description provided for @actionClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get actionClose;

  /// No description provided for @actionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get actionRetry;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get commonNone;

  /// No description provided for @commonLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get commonLoading;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonError;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get commonOptional;

  /// No description provided for @commonYes.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get commonYes;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navSites.
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get navSites;

  /// No description provided for @navStats.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @onboardingWelcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to BetBook'**
  String get onboardingWelcomeTitle;

  /// No description provided for @onboardingWelcomeBody.
  ///
  /// In en, this message translates to:
  /// **'Track your deposits and withdrawals across betting sites and see your real profit or loss. Everything stays on your device.'**
  String get onboardingWelcomeBody;

  /// No description provided for @onboardingLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose your language'**
  String get onboardingLanguageTitle;

  /// No description provided for @onboardingThemeTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a theme'**
  String get onboardingThemeTitle;

  /// No description provided for @onboardingCurrencyTitle.
  ///
  /// In en, this message translates to:
  /// **'Your main currency'**
  String get onboardingCurrencyTitle;

  /// No description provided for @onboardingCurrencyBody.
  ///
  /// In en, this message translates to:
  /// **'Totals across all sites are shown in this currency. You can change it later in Settings.'**
  String get onboardingCurrencyBody;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get started'**
  String get onboardingGetStarted;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDanish.
  ///
  /// In en, this message translates to:
  /// **'Dansk'**
  String get languageDanish;

  /// No description provided for @dashboardTitle.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboardTitle;

  /// No description provided for @dashboardNetResult.
  ///
  /// In en, this message translates to:
  /// **'Net result'**
  String get dashboardNetResult;

  /// No description provided for @dashboardProfit.
  ///
  /// In en, this message translates to:
  /// **'Profit'**
  String get dashboardProfit;

  /// No description provided for @dashboardLoss.
  ///
  /// In en, this message translates to:
  /// **'Loss'**
  String get dashboardLoss;

  /// No description provided for @dashboardBreakEven.
  ///
  /// In en, this message translates to:
  /// **'Break-even'**
  String get dashboardBreakEven;

  /// No description provided for @dashboardTotalDeposited.
  ///
  /// In en, this message translates to:
  /// **'Deposited'**
  String get dashboardTotalDeposited;

  /// No description provided for @dashboardTotalWithdrawn.
  ///
  /// In en, this message translates to:
  /// **'Withdrawn'**
  String get dashboardTotalWithdrawn;

  /// No description provided for @dashboardProfitOverTime.
  ///
  /// In en, this message translates to:
  /// **'Profit over time'**
  String get dashboardProfitOverTime;

  /// No description provided for @dashboardYourSites.
  ///
  /// In en, this message translates to:
  /// **'Your sites'**
  String get dashboardYourSites;

  /// No description provided for @dashboardSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get dashboardSeeAll;

  /// No description provided for @dashboardEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing tracked yet'**
  String get dashboardEmptyTitle;

  /// No description provided for @dashboardEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add your first deposit or withdrawal and BetBook will show you, honestly, where you stand.'**
  String get dashboardEmptyBody;

  /// No description provided for @dashboardAddSite.
  ///
  /// In en, this message translates to:
  /// **'Add a site'**
  String get dashboardAddSite;

  /// No description provided for @dashboardAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get dashboardAllTime;

  /// No description provided for @dashboardUpOverall.
  ///
  /// In en, this message translates to:
  /// **'You\'re up overall'**
  String get dashboardUpOverall;

  /// No description provided for @dashboardDownOverall.
  ///
  /// In en, this message translates to:
  /// **'You\'re down overall'**
  String get dashboardDownOverall;

  /// No description provided for @dashboardEvenOverall.
  ///
  /// In en, this message translates to:
  /// **'You\'re breaking even'**
  String get dashboardEvenOverall;

  /// No description provided for @allDataOnDevice.
  ///
  /// In en, this message translates to:
  /// **'All data stays on your device'**
  String get allDataOnDevice;

  /// No description provided for @sitesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No sites yet'**
  String get sitesEmptyTitle;

  /// No description provided for @sitesEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the first site you play on, so you can track your deposits and withdrawals.'**
  String get sitesEmptyBody;

  /// No description provided for @siteDetailEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions here yet'**
  String get siteDetailEmptyTitle;

  /// No description provided for @siteDetailEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'This site is set up. Add the first deposit or withdrawal to start the ledger.'**
  String get siteDetailEmptyBody;

  /// No description provided for @commonCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commonCurrency;

  /// No description provided for @txSaveTransaction.
  ///
  /// In en, this message translates to:
  /// **'Save transaction'**
  String get txSaveTransaction;

  /// No description provided for @txRunningNet.
  ///
  /// In en, this message translates to:
  /// **'net {amount}'**
  String txRunningNet(String amount);

  /// No description provided for @sitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Sites'**
  String get sitesTitle;

  /// No description provided for @siteAdd.
  ///
  /// In en, this message translates to:
  /// **'Add site'**
  String get siteAdd;

  /// No description provided for @siteEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit site'**
  String get siteEdit;

  /// No description provided for @siteNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Site name'**
  String get siteNameLabel;

  /// No description provided for @siteNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Bet365, Unibet…'**
  String get siteNameHint;

  /// No description provided for @siteCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get siteCurrencyLabel;

  /// No description provided for @siteColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get siteColorLabel;

  /// No description provided for @siteDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete site'**
  String get siteDelete;

  /// No description provided for @siteDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this site and all of its transactions? This cannot be undone.'**
  String get siteDeleteConfirm;

  /// No description provided for @siteNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get siteNet;

  /// No description provided for @sitesCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No sites} =1{1 site} other{{count} sites}}'**
  String sitesCount(int count);

  /// No description provided for @siteEmptyTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get siteEmptyTransactions;

  /// No description provided for @siteTransactionCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}'**
  String siteTransactionCount(int count);

  /// No description provided for @txAdd.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get txAdd;

  /// No description provided for @txEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get txEdit;

  /// No description provided for @txTypeDeposit.
  ///
  /// In en, this message translates to:
  /// **'Deposit'**
  String get txTypeDeposit;

  /// No description provided for @txTypeWithdrawal.
  ///
  /// In en, this message translates to:
  /// **'Withdrawal'**
  String get txTypeWithdrawal;

  /// No description provided for @txAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txAmount;

  /// No description provided for @txDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDate;

  /// No description provided for @txSite.
  ///
  /// In en, this message translates to:
  /// **'Site'**
  String get txSite;

  /// No description provided for @txSelectSite.
  ///
  /// In en, this message translates to:
  /// **'Select a site'**
  String get txSelectSite;

  /// No description provided for @txNoSitesTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a site first'**
  String get txNoSitesTitle;

  /// No description provided for @txNoSitesBody.
  ///
  /// In en, this message translates to:
  /// **'You need a site before you can log a transaction. Add the one you play on to get started.'**
  String get txNoSitesBody;

  /// No description provided for @txNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txNote;

  /// No description provided for @txNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional note'**
  String get txNoteHint;

  /// No description provided for @txDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get txDelete;

  /// No description provided for @txDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction? This cannot be undone.'**
  String get txDeleteConfirm;

  /// No description provided for @txAmountError.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than zero'**
  String get txAmountError;

  /// No description provided for @statsTitle.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// No description provided for @statsRangeLast7.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get statsRangeLast7;

  /// No description provided for @statsRangeLast30.
  ///
  /// In en, this message translates to:
  /// **'30 days'**
  String get statsRangeLast30;

  /// No description provided for @statsRangeLast90.
  ///
  /// In en, this message translates to:
  /// **'90 days'**
  String get statsRangeLast90;

  /// No description provided for @statsRangeYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get statsRangeYear;

  /// No description provided for @statsRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get statsRangeAll;

  /// No description provided for @statsNetResult.
  ///
  /// In en, this message translates to:
  /// **'Net result'**
  String get statsNetResult;

  /// No description provided for @statsByMonth.
  ///
  /// In en, this message translates to:
  /// **'By month'**
  String get statsByMonth;

  /// No description provided for @statsBySite.
  ///
  /// In en, this message translates to:
  /// **'By site'**
  String get statsBySite;

  /// No description provided for @statsBestSite.
  ///
  /// In en, this message translates to:
  /// **'Best site'**
  String get statsBestSite;

  /// No description provided for @statsWorstSite.
  ///
  /// In en, this message translates to:
  /// **'Worst site'**
  String get statsWorstSite;

  /// No description provided for @statsNoData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data yet'**
  String get statsNoData;

  /// No description provided for @statsNoDataBody.
  ///
  /// In en, this message translates to:
  /// **'Add a few transactions to see your trends here.'**
  String get statsNoDataBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionGeneral.
  ///
  /// In en, this message translates to:
  /// **'General'**
  String get settingsSectionGeneral;

  /// No description provided for @settingsSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get settingsSectionSecurity;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsSectionResponsible.
  ///
  /// In en, this message translates to:
  /// **'Responsible gambling'**
  String get settingsSectionResponsible;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsBaseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Main currency'**
  String get settingsBaseCurrency;

  /// No description provided for @settingsExchangeRates.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get settingsExchangeRates;

  /// No description provided for @settingsAppLock.
  ///
  /// In en, this message translates to:
  /// **'App lock'**
  String get settingsAppLock;

  /// No description provided for @settingsAppLockSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Require biometrics or a PIN to open the app'**
  String get settingsAppLockSubtitle;

  /// No description provided for @settingsBiometric.
  ///
  /// In en, this message translates to:
  /// **'Use biometrics'**
  String get settingsBiometric;

  /// No description provided for @settingsChangePin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get settingsChangePin;

  /// No description provided for @settingsSetPin.
  ///
  /// In en, this message translates to:
  /// **'Set a PIN'**
  String get settingsSetPin;

  /// No description provided for @settingsExport.
  ///
  /// In en, this message translates to:
  /// **'Export backup'**
  String get settingsExport;

  /// No description provided for @settingsExportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Save all your data to a file'**
  String get settingsExportSubtitle;

  /// No description provided for @settingsImport.
  ///
  /// In en, this message translates to:
  /// **'Import backup'**
  String get settingsImport;

  /// No description provided for @settingsImportSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Restore data from a backup file'**
  String get settingsImportSubtitle;

  /// No description provided for @settingsClearData.
  ///
  /// In en, this message translates to:
  /// **'Clear all data'**
  String get settingsClearData;

  /// No description provided for @settingsClearDataSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete everything on this device'**
  String get settingsClearDataSubtitle;

  /// No description provided for @settingsClearDataConfirm.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all sites and transactions. Consider exporting a backup first. Continue?'**
  String get settingsClearDataConfirm;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get settingsVersion;

  /// No description provided for @settingsLicenses.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get settingsLicenses;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyBody.
  ///
  /// In en, this message translates to:
  /// **'BetBook stores all of your data locally on this device. Nothing is uploaded, shared, or tracked. Keep a backup so you don\'t lose your history.'**
  String get settingsPrivacyBody;

  /// No description provided for @exchangeRatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Exchange rates'**
  String get exchangeRatesTitle;

  /// No description provided for @exchangeRatesBody.
  ///
  /// In en, this message translates to:
  /// **'Rates convert each site\'s currency into your main currency ({base}) for totals. Edit them to match your own numbers.'**
  String exchangeRatesBody(String base);

  /// No description provided for @exchangeRatesAddCurrency.
  ///
  /// In en, this message translates to:
  /// **'Add currency'**
  String get exchangeRatesAddCurrency;

  /// No description provided for @exchangeRatesCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom currency…'**
  String get exchangeRatesCustom;

  /// No description provided for @exchangeRatesCustomCode.
  ///
  /// In en, this message translates to:
  /// **'3-letter code (e.g. JPY)'**
  String get exchangeRatesCustomCode;

  /// No description provided for @exchangeRatesCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a 3-letter currency code'**
  String get exchangeRatesCodeInvalid;

  /// No description provided for @exchangeRatesCodeTaken.
  ///
  /// In en, this message translates to:
  /// **'That currency already exists'**
  String get exchangeRatesCodeTaken;

  /// No description provided for @exchangeRatesOneBase.
  ///
  /// In en, this message translates to:
  /// **'1 {base} ='**
  String exchangeRatesOneBase(String base);

  /// No description provided for @exchangeRatesBaseRow.
  ///
  /// In en, this message translates to:
  /// **'Main currency'**
  String get exchangeRatesBaseRow;

  /// No description provided for @ratesAutoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Auto-update rates weekly'**
  String get ratesAutoUpdate;

  /// No description provided for @ratesAutoUpdateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Fetch public reference rates (ECB) automatically'**
  String get ratesAutoUpdateSubtitle;

  /// No description provided for @ratesRefreshNow.
  ///
  /// In en, this message translates to:
  /// **'Update rates now'**
  String get ratesRefreshNow;

  /// No description provided for @ratesLastUpdated.
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String ratesLastUpdated(String date);

  /// No description provided for @ratesNever.
  ///
  /// In en, this message translates to:
  /// **'never'**
  String get ratesNever;

  /// No description provided for @ratesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rates updated'**
  String get ratesUpdated;

  /// No description provided for @ratesUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t update rates. Check your connection.'**
  String get ratesUpdateFailed;

  /// No description provided for @lockTitle.
  ///
  /// In en, this message translates to:
  /// **'BetBook is locked'**
  String get lockTitle;

  /// No description provided for @lockUnlock.
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get lockUnlock;

  /// No description provided for @lockUseBiometrics.
  ///
  /// In en, this message translates to:
  /// **'Unlock with biometrics'**
  String get lockUseBiometrics;

  /// No description provided for @lockInstruction.
  ///
  /// In en, this message translates to:
  /// **'Use your fingerprint or enter your PIN'**
  String get lockInstruction;

  /// No description provided for @lockEnterPin.
  ///
  /// In en, this message translates to:
  /// **'Enter your PIN'**
  String get lockEnterPin;

  /// No description provided for @lockSetPin.
  ///
  /// In en, this message translates to:
  /// **'Choose a PIN'**
  String get lockSetPin;

  /// No description provided for @lockConfirmPin.
  ///
  /// In en, this message translates to:
  /// **'Confirm your PIN'**
  String get lockConfirmPin;

  /// No description provided for @lockPinMismatch.
  ///
  /// In en, this message translates to:
  /// **'PINs don\'t match, try again'**
  String get lockPinMismatch;

  /// No description provided for @lockWrongPin.
  ///
  /// In en, this message translates to:
  /// **'Wrong PIN'**
  String get lockWrongPin;

  /// No description provided for @lockForgotPin.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN?'**
  String get lockForgotPin;

  /// No description provided for @rgTitle.
  ///
  /// In en, this message translates to:
  /// **'Responsible gambling'**
  String get rgTitle;

  /// No description provided for @rgIntro.
  ///
  /// In en, this message translates to:
  /// **'These optional tools help you stay in control. BetBook only tracks money — it never encourages betting.'**
  String get rgIntro;

  /// No description provided for @rgDepositLimit.
  ///
  /// In en, this message translates to:
  /// **'Deposit limit'**
  String get rgDepositLimit;

  /// No description provided for @rgDepositLimitSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get warned when deposits pass a limit'**
  String get rgDepositLimitSubtitle;

  /// No description provided for @rgNetLossAlert.
  ///
  /// In en, this message translates to:
  /// **'Net-loss alert'**
  String get rgNetLossAlert;

  /// No description provided for @rgNetLossAlertSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Get warned when your net loss passes an amount'**
  String get rgNetLossAlertSubtitle;

  /// No description provided for @rgPeriodDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get rgPeriodDaily;

  /// No description provided for @rgPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get rgPeriodWeekly;

  /// No description provided for @rgPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get rgPeriodMonthly;

  /// No description provided for @rgLimitAmount.
  ///
  /// In en, this message translates to:
  /// **'Limit amount'**
  String get rgLimitAmount;

  /// No description provided for @rgExceededDeposit.
  ///
  /// In en, this message translates to:
  /// **'You\'ve passed your {period} deposit limit of {amount}.'**
  String rgExceededDeposit(String period, String amount);

  /// No description provided for @rgExceededLoss.
  ///
  /// In en, this message translates to:
  /// **'Your net loss has passed {amount}.'**
  String rgExceededLoss(String amount);

  /// No description provided for @rgHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'Need to talk to someone?'**
  String get rgHelpTitle;

  /// No description provided for @rgHelpBody.
  ///
  /// In en, this message translates to:
  /// **'If gambling stops being fun, help is available. In Denmark call StopSpillet on 70 22 28 25.'**
  String get rgHelpBody;

  /// No description provided for @backupExportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup saved'**
  String get backupExportSuccess;

  /// No description provided for @backupImportSuccess.
  ///
  /// In en, this message translates to:
  /// **'Backup imported'**
  String get backupImportSuccess;

  /// No description provided for @backupImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Importing replaces all current data with the backup\'s contents. Continue?'**
  String get backupImportConfirm;

  /// No description provided for @backupInvalidFile.
  ///
  /// In en, this message translates to:
  /// **'That file isn\'t a valid BetBook backup'**
  String get backupInvalidFile;

  /// No description provided for @quickAddDatedNow.
  ///
  /// In en, this message translates to:
  /// **'Dated now · today {time}'**
  String quickAddDatedNow(String time);

  /// No description provided for @quickAddSaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved'**
  String get quickAddSaved;

  /// No description provided for @repeatEntry.
  ///
  /// In en, this message translates to:
  /// **'Repeat entry'**
  String get repeatEntry;

  /// No description provided for @repeatThisEntry.
  ///
  /// In en, this message translates to:
  /// **'Repeat this entry'**
  String get repeatThisEntry;

  /// No description provided for @reminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get reminders;

  /// No description provided for @limitWarnings.
  ///
  /// In en, this message translates to:
  /// **'Limit warnings'**
  String get limitWarnings;

  /// No description provided for @limitWarningsSub.
  ///
  /// In en, this message translates to:
  /// **'At 80% and 100% of your deposit limit'**
  String get limitWarningsSub;

  /// No description provided for @setLimitFirst.
  ///
  /// In en, this message translates to:
  /// **'Set a limit first'**
  String get setLimitFirst;

  /// No description provided for @notifRationaleTitle.
  ///
  /// In en, this message translates to:
  /// **'Reminders on your phone'**
  String get notifRationaleTitle;

  /// No description provided for @notifRationaleBody.
  ///
  /// In en, this message translates to:
  /// **'BetBook creates reminders on your phone. Nothing is sent to a server, and there is no account.'**
  String get notifRationaleBody;

  /// No description provided for @notNow.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get notNow;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @notifDisabledSystem.
  ///
  /// In en, this message translates to:
  /// **'Reminders are turned off in system settings.'**
  String get notifDisabledSystem;

  /// No description provided for @openSettings.
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettings;

  /// No description provided for @limitChannelName.
  ///
  /// In en, this message translates to:
  /// **'Limit warnings'**
  String get limitChannelName;

  /// No description provided for @limitChannelDesc.
  ///
  /// In en, this message translates to:
  /// **'When you approach or reach a limit you set'**
  String get limitChannelDesc;

  /// No description provided for @limitPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'day'**
  String get limitPeriodDay;

  /// No description provided for @limitPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'week'**
  String get limitPeriodWeek;

  /// No description provided for @limitPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'month'**
  String get limitPeriodMonth;

  /// No description provided for @limitApproachTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve used 80% of your deposit limit'**
  String get limitApproachTitle;

  /// No description provided for @limitApproachBody.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} this {period}. Your limit is in Settings if you want to adjust it.'**
  String limitApproachBody(String used, String limit, String period);

  /// No description provided for @limitReachedTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your deposit limit'**
  String get limitReachedTitle;

  /// No description provided for @limitReachedBody.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} this {period}. Take a break or adjust your limit — both are in Settings.'**
  String limitReachedBody(String used, String limit, String period);

  /// No description provided for @netLossTitle.
  ///
  /// In en, this message translates to:
  /// **'Your net loss passed {amount}'**
  String netLossTitle(String amount);

  /// No description provided for @netLossBody.
  ///
  /// In en, this message translates to:
  /// **'That\'s the alert you set. Tap to review your limits.'**
  String get netLossBody;

  /// No description provided for @limitUsedPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of your limit used'**
  String limitUsedPct(int pct);

  /// No description provided for @limitReachedLabel.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached your limit'**
  String get limitReachedLabel;

  /// No description provided for @netLossLabel.
  ///
  /// In en, this message translates to:
  /// **'Your net loss alert'**
  String get netLossLabel;

  /// No description provided for @limitFigureLine.
  ///
  /// In en, this message translates to:
  /// **'{used} of {limit} this {period}'**
  String limitFigureLine(String used, String limit, String period);

  /// No description provided for @adjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get adjust;

  /// No description provided for @takeABreak.
  ///
  /// In en, this message translates to:
  /// **'Take a break'**
  String get takeABreak;

  /// No description provided for @takeABreakSub.
  ///
  /// In en, this message translates to:
  /// **'Hide totals and pause reminders'**
  String get takeABreakSub;

  /// No description provided for @takeABreakDesc.
  ///
  /// In en, this message translates to:
  /// **'Totals are hidden and reminders pause. Logging still works, and you can end the break any time.'**
  String get takeABreakDesc;

  /// No description provided for @breakOption24h.
  ///
  /// In en, this message translates to:
  /// **'24 hours'**
  String get breakOption24h;

  /// No description provided for @breakOption1week.
  ///
  /// In en, this message translates to:
  /// **'1 week'**
  String get breakOption1week;

  /// No description provided for @breakOption1month.
  ///
  /// In en, this message translates to:
  /// **'1 month'**
  String get breakOption1month;

  /// No description provided for @breakUntil.
  ///
  /// In en, this message translates to:
  /// **'Break until {date}'**
  String breakUntil(String date);

  /// No description provided for @endBreak.
  ///
  /// In en, this message translates to:
  /// **'End break'**
  String get endBreak;

  /// No description provided for @showTotals.
  ///
  /// In en, this message translates to:
  /// **'Show totals'**
  String get showTotals;

  /// No description provided for @settingsImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get settingsImportCsv;

  /// No description provided for @settingsImportCsvSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Add transactions from a CSV file'**
  String get settingsImportCsvSubtitle;

  /// No description provided for @csvImportConfirm.
  ///
  /// In en, this message translates to:
  /// **'Transactions in the file will be added to your current data. Sites are matched by name and created when missing.'**
  String get csvImportConfirm;

  /// No description provided for @csvImportAdded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction added} other{{count} transactions added}}'**
  String csvImportAdded(int count);

  /// No description provided for @csvImportSkipped.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 row skipped} other{{count} rows skipped}}'**
  String csvImportSkipped(int count);

  /// No description provided for @toastSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get toastSaved;

  /// No description provided for @toastDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted'**
  String get toastDeleted;
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
      <String>['da', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'da':
      return AppLocalizationsDa();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
