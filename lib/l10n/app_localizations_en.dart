// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'BetBook';

  @override
  String get actionSave => 'Save';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionDelete => 'Delete';

  @override
  String get actionEdit => 'Edit';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionDone => 'Done';

  @override
  String get actionNext => 'Next';

  @override
  String get actionBack => 'Back';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionConfirm => 'Confirm';

  @override
  String get actionUndo => 'Undo';

  @override
  String siteDeletedSnack(String name) {
    return '$name deleted';
  }

  @override
  String get txDeletedSnack => 'Transaction deleted';

  @override
  String rateDeletedSnack(String code) {
    return '$code rate removed';
  }

  @override
  String get actionClose => 'Close';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionContinue => 'Continue';

  @override
  String get commonAll => 'All';

  @override
  String get commonNone => 'None';

  @override
  String get commonLoading => 'Loading…';

  @override
  String get commonError => 'Something went wrong';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonOptional => 'Optional';

  @override
  String get commonYes => 'Yes';

  @override
  String get commonNo => 'No';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navSites => 'Sites';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String get onboardingWelcomeTitle => 'Welcome to BetBook';

  @override
  String get onboardingWelcomeBody =>
      'Track your deposits and withdrawals across betting sites and see your real profit or loss. Everything stays on your device.';

  @override
  String get onboardingLanguageTitle => 'Choose your language';

  @override
  String get onboardingThemeTitle => 'Pick a theme';

  @override
  String get onboardingCurrencyTitle => 'Your main currency';

  @override
  String get onboardingCurrencyBody =>
      'Totals across all sites are shown in this currency. You can change it later in Settings.';

  @override
  String get onboardingGetStarted => 'Get started';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDanish => 'Dansk';

  @override
  String get dashboardTitle => 'Dashboard';

  @override
  String get dashboardNetResult => 'Net result';

  @override
  String get dashboardProfit => 'Profit';

  @override
  String get dashboardLoss => 'Loss';

  @override
  String get dashboardBreakEven => 'Break-even';

  @override
  String get dashboardTotalDeposited => 'Deposited';

  @override
  String get dashboardTotalWithdrawn => 'Withdrawn';

  @override
  String get dashboardProfitOverTime => 'Profit over time';

  @override
  String get dashboardYourSites => 'Your sites';

  @override
  String get dashboardSeeAll => 'See all';

  @override
  String get dashboardEmptyTitle => 'Nothing tracked yet';

  @override
  String get dashboardEmptyBody =>
      'Add your first deposit or withdrawal and BetBook will show you, honestly, where you stand.';

  @override
  String get dashboardAddSite => 'Add a site';

  @override
  String get dashboardAllTime => 'All time';

  @override
  String get dashboardUpOverall => 'You\'re up overall';

  @override
  String get dashboardDownOverall => 'You\'re down overall';

  @override
  String get dashboardEvenOverall => 'You\'re breaking even';

  @override
  String get allDataOnDevice => 'All data stays on your device';

  @override
  String get sitesEmptyTitle => 'No sites yet';

  @override
  String get sitesEmptyBody =>
      'Add the first site you play on, so you can track your deposits and withdrawals.';

  @override
  String get siteDetailEmptyTitle => 'No transactions here yet';

  @override
  String get siteDetailEmptyBody =>
      'This site is set up. Add the first deposit or withdrawal to start the ledger.';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get txSaveTransaction => 'Save transaction';

  @override
  String txRunningNet(String amount) {
    return 'net $amount';
  }

  @override
  String get sitesTitle => 'Sites';

  @override
  String get siteAdd => 'Add site';

  @override
  String get siteEdit => 'Edit site';

  @override
  String get siteNameLabel => 'Site name';

  @override
  String get siteNameHint => 'e.g. Bet365, Unibet…';

  @override
  String get siteCurrencyLabel => 'Currency';

  @override
  String get siteColorLabel => 'Colour';

  @override
  String get siteDelete => 'Delete site';

  @override
  String get siteDeleteConfirm =>
      'Delete this site and all of its transactions? This cannot be undone.';

  @override
  String get siteNet => 'Net';

  @override
  String sitesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count sites',
      one: '1 site',
      zero: 'No sites',
    );
    return '$_temp0';
  }

  @override
  String get siteEmptyTransactions => 'No transactions yet';

  @override
  String siteTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return '$_temp0';
  }

  @override
  String get txAdd => 'Add transaction';

  @override
  String get txEdit => 'Edit transaction';

  @override
  String get txTypeDeposit => 'Deposit';

  @override
  String get txTypeWithdrawal => 'Withdrawal';

  @override
  String get txAmount => 'Amount';

  @override
  String get txDate => 'Date';

  @override
  String get txSite => 'Site';

  @override
  String get txSelectSite => 'Select a site';

  @override
  String get txNote => 'Note';

  @override
  String get txNoteHint => 'Optional note';

  @override
  String get txDelete => 'Delete transaction';

  @override
  String get txDeleteConfirm =>
      'Delete this transaction? This cannot be undone.';

  @override
  String get txAmountError => 'Enter an amount greater than zero';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsRangeLast7 => '7 days';

  @override
  String get statsRangeLast30 => '30 days';

  @override
  String get statsRangeLast90 => '90 days';

  @override
  String get statsRangeYear => 'This year';

  @override
  String get statsRangeAll => 'All time';

  @override
  String get statsNetResult => 'Net result';

  @override
  String get statsByMonth => 'By month';

  @override
  String get statsBySite => 'By site';

  @override
  String get statsBestSite => 'Best site';

  @override
  String get statsWorstSite => 'Worst site';

  @override
  String get statsNoData => 'Not enough data yet';

  @override
  String get statsNoDataBody =>
      'Add a few transactions to see your trends here.';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionGeneral => 'General';

  @override
  String get settingsSectionSecurity => 'Security';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionResponsible => 'Responsible gambling';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsBaseCurrency => 'Main currency';

  @override
  String get settingsExchangeRates => 'Exchange rates';

  @override
  String get settingsAppLock => 'App lock';

  @override
  String get settingsAppLockSubtitle =>
      'Require biometrics or a PIN to open the app';

  @override
  String get settingsBiometric => 'Use biometrics';

  @override
  String get settingsChangePin => 'Change PIN';

  @override
  String get settingsSetPin => 'Set a PIN';

  @override
  String get settingsExport => 'Export backup';

  @override
  String get settingsExportSubtitle => 'Save all your data to a file';

  @override
  String get settingsImport => 'Import backup';

  @override
  String get settingsImportSubtitle => 'Restore data from a backup file';

  @override
  String get settingsClearData => 'Clear all data';

  @override
  String get settingsClearDataSubtitle =>
      'Permanently delete everything on this device';

  @override
  String get settingsClearDataConfirm =>
      'This permanently deletes all sites and transactions. Consider exporting a backup first. Continue?';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open-source licences';

  @override
  String get settingsPrivacy => 'Privacy';

  @override
  String get settingsPrivacyBody =>
      'BetBook stores all of your data locally on this device. Nothing is uploaded, shared, or tracked. Keep a backup so you don\'t lose your history.';

  @override
  String get exchangeRatesTitle => 'Exchange rates';

  @override
  String exchangeRatesBody(String base) {
    return 'Rates convert each site\'s currency into your main currency ($base) for totals. Edit them to match your own numbers.';
  }

  @override
  String get exchangeRatesAddCurrency => 'Add currency';

  @override
  String get exchangeRatesCustom => 'Custom currency…';

  @override
  String get exchangeRatesCustomCode => '3-letter code (e.g. JPY)';

  @override
  String get exchangeRatesCodeInvalid => 'Enter a 3-letter currency code';

  @override
  String get exchangeRatesCodeTaken => 'That currency already exists';

  @override
  String exchangeRatesOneBase(String base) {
    return '1 $base =';
  }

  @override
  String get exchangeRatesBaseRow => 'Main currency';

  @override
  String get ratesAutoUpdate => 'Auto-update rates weekly';

  @override
  String get ratesAutoUpdateSubtitle =>
      'Fetch public reference rates (ECB) automatically';

  @override
  String get ratesRefreshNow => 'Update rates now';

  @override
  String ratesLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get ratesNever => 'never';

  @override
  String get ratesUpdated => 'Rates updated';

  @override
  String get ratesUpdateFailed =>
      'Couldn\'t update rates. Check your connection.';

  @override
  String get lockTitle => 'BetBook is locked';

  @override
  String get lockUnlock => 'Unlock';

  @override
  String get lockUseBiometrics => 'Unlock with biometrics';

  @override
  String get lockInstruction => 'Use your fingerprint or enter your PIN';

  @override
  String get lockEnterPin => 'Enter your PIN';

  @override
  String get lockSetPin => 'Choose a PIN';

  @override
  String get lockConfirmPin => 'Confirm your PIN';

  @override
  String get lockPinMismatch => 'PINs don\'t match, try again';

  @override
  String get lockWrongPin => 'Wrong PIN';

  @override
  String get lockForgotPin => 'Forgot PIN?';

  @override
  String get rgTitle => 'Responsible gambling';

  @override
  String get rgIntro =>
      'These optional tools help you stay in control. BetBook only tracks money — it never encourages betting.';

  @override
  String get rgDepositLimit => 'Deposit limit';

  @override
  String get rgDepositLimitSubtitle => 'Get warned when deposits pass a limit';

  @override
  String get rgNetLossAlert => 'Net-loss alert';

  @override
  String get rgNetLossAlertSubtitle =>
      'Get warned when your net loss passes an amount';

  @override
  String get rgPeriodDaily => 'Daily';

  @override
  String get rgPeriodWeekly => 'Weekly';

  @override
  String get rgPeriodMonthly => 'Monthly';

  @override
  String get rgLimitAmount => 'Limit amount';

  @override
  String rgExceededDeposit(String period, String amount) {
    return 'You\'ve passed your $period deposit limit of $amount.';
  }

  @override
  String rgExceededLoss(String amount) {
    return 'Your net loss has passed $amount.';
  }

  @override
  String get rgHelpTitle => 'Need to talk to someone?';

  @override
  String get rgHelpBody =>
      'If gambling stops being fun, help is available. In Denmark call StopSpillet on 70 22 28 25.';

  @override
  String get backupExportSuccess => 'Backup saved';

  @override
  String get backupImportSuccess => 'Backup imported';

  @override
  String get backupImportConfirm =>
      'Importing replaces all current data with the backup\'s contents. Continue?';

  @override
  String get backupInvalidFile => 'That file isn\'t a valid BetBook backup';

  @override
  String quickAddDatedNow(String time) {
    return 'Dated now · today $time';
  }

  @override
  String get quickAddSaved => 'Entry saved';

  @override
  String get repeatEntry => 'Repeat entry';

  @override
  String get repeatThisEntry => 'Repeat this entry';

  @override
  String get reminders => 'Reminders';

  @override
  String get weeklySummary => 'Weekly summary';

  @override
  String get weeklySummarySub => 'Every Monday at 09:00';

  @override
  String get limitWarnings => 'Limit warnings';

  @override
  String get limitWarningsSub => 'At 80% and 100% of your deposit limit';

  @override
  String get setLimitFirst => 'Set a limit first';

  @override
  String get notifRationaleTitle => 'Reminders on your phone';

  @override
  String get notifRationaleBody =>
      'BetBook creates reminders on your phone. Nothing is sent to a server, and there is no account.';

  @override
  String get notNow => 'Not now';

  @override
  String get continueLabel => 'Continue';

  @override
  String get notifDisabledSystem =>
      'Reminders are turned off in system settings.';

  @override
  String get openSettings => 'Open settings';

  @override
  String get weeklyChannelName => 'Weekly summary';

  @override
  String get weeklyChannelDesc => 'Your week in numbers, once a week';

  @override
  String get limitChannelName => 'Limit warnings';

  @override
  String get limitChannelDesc => 'When you approach or reach a limit you set';

  @override
  String get lastWeek => 'Last week';

  @override
  String get seeTheWeek => 'See the week';

  @override
  String get noEntriesLastWeek => 'No entries last week.';

  @override
  String get weeklyNudgeBody => 'Tap to see your week.';

  @override
  String weeklyLossBody(String amount, int sites) {
    String _temp0 = intl.Intl.pluralLogic(
      sites,
      locale: localeName,
      other: '$sites sites',
      one: '1 site',
    );
    return 'You\'re down $amount across $_temp0.';
  }

  @override
  String weeklyWinBody(String amount, int sites) {
    String _temp0 = intl.Intl.pluralLogic(
      sites,
      locale: localeName,
      other: '$sites sites',
      one: '1 site',
    );
    return 'You\'re up $amount across $_temp0.';
  }

  @override
  String get weeklyEvenBody => 'Deposits and withdrawals balanced out.';

  @override
  String get limitPeriodDay => 'day';

  @override
  String get limitPeriodWeek => 'week';

  @override
  String get limitPeriodMonth => 'month';

  @override
  String get limitApproachTitle => 'You\'ve used 80% of your deposit limit';

  @override
  String limitApproachBody(String used, String limit, String period) {
    return '$used of $limit this $period. Your limit is in Settings if you want to adjust it.';
  }

  @override
  String get limitReachedTitle => 'You\'ve reached your deposit limit';

  @override
  String limitReachedBody(String used, String limit, String period) {
    return '$used of $limit this $period. Take a break or adjust your limit — both are in Settings.';
  }

  @override
  String netLossTitle(String amount) {
    return 'Your net loss passed $amount';
  }

  @override
  String get netLossBody =>
      'That\'s the alert you set. Tap to review your limits.';

  @override
  String limitUsedPct(int pct) {
    return '$pct% of your limit used';
  }

  @override
  String get limitReachedLabel => 'You\'ve reached your limit';

  @override
  String get netLossLabel => 'Your net loss alert';

  @override
  String limitFigureLine(String used, String limit, String period) {
    return '$used of $limit this $period';
  }

  @override
  String get adjust => 'Adjust';

  @override
  String get takeABreak => 'Take a break';

  @override
  String get takeABreakSub => 'Hide totals and pause reminders';

  @override
  String get takeABreakDesc =>
      'Totals are hidden and reminders pause. Logging still works, and you can end the break any time.';

  @override
  String get breakOption24h => '24 hours';

  @override
  String get breakOption1week => '1 week';

  @override
  String get breakOption1month => '1 month';

  @override
  String breakUntil(String date) {
    return 'Break until $date';
  }

  @override
  String get endBreak => 'End break';

  @override
  String get showTotals => 'Show totals';

  @override
  String get settingsImportCsv => 'Import CSV';

  @override
  String get settingsImportCsvSubtitle => 'Add transactions from a CSV file';

  @override
  String get csvImportConfirm =>
      'Transactions in the file will be added to your current data. Sites are matched by name and created when missing.';

  @override
  String csvImportAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions added',
      one: '1 transaction added',
    );
    return '$_temp0';
  }

  @override
  String csvImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rows skipped',
      one: '1 row skipped',
    );
    return '$_temp0';
  }

  @override
  String get toastSaved => 'Saved';

  @override
  String get toastDeleted => 'Deleted';
}
