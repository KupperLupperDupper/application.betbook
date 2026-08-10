// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Danish (`da`).
class AppLocalizationsDa extends AppLocalizations {
  AppLocalizationsDa([String locale = 'da']) : super(locale);

  @override
  String get appName => 'BetBook';

  @override
  String get actionSave => 'Gem';

  @override
  String get actionCancel => 'Annuller';

  @override
  String get actionDelete => 'Slet';

  @override
  String get actionEdit => 'Rediger';

  @override
  String get actionAdd => 'Tilføj';

  @override
  String get actionDone => 'Færdig';

  @override
  String get actionNext => 'Næste';

  @override
  String get actionBack => 'Tilbage';

  @override
  String get actionSkip => 'Spring over';

  @override
  String get actionConfirm => 'Bekræft';

  @override
  String get actionUndo => 'Fortryd';

  @override
  String siteDeletedSnack(String name) {
    return '$name slettet';
  }

  @override
  String get txDeletedSnack => 'Transaktion slettet';

  @override
  String rateDeletedSnack(String code) {
    return '$code-kurs fjernet';
  }

  @override
  String get actionClose => 'Luk';

  @override
  String get actionRetry => 'Prøv igen';

  @override
  String get actionContinue => 'Fortsæt';

  @override
  String get commonAll => 'Alle';

  @override
  String get commonNone => 'Ingen';

  @override
  String get commonLoading => 'Indlæser…';

  @override
  String get commonError => 'Noget gik galt';

  @override
  String get commonRequired => 'Påkrævet';

  @override
  String get commonOptional => 'Valgfri';

  @override
  String get commonYes => 'Ja';

  @override
  String get commonNo => 'Nej';

  @override
  String get navDashboard => 'Overblik';

  @override
  String get navSites => 'Sider';

  @override
  String get navStats => 'Statistik';

  @override
  String get navSettings => 'Indstillinger';

  @override
  String get onboardingWelcomeTitle => 'Velkommen til BetBook';

  @override
  String get onboardingWelcomeBody =>
      'Hold styr på dine indbetalinger og udbetalinger på tværs af spilsider, og se dit reelle overskud eller tab. Alt bliver på din enhed.';

  @override
  String get onboardingLanguageTitle => 'Vælg dit sprog';

  @override
  String get onboardingThemeTitle => 'Vælg et tema';

  @override
  String get onboardingCurrencyTitle => 'Din hovedvaluta';

  @override
  String get onboardingCurrencyBody =>
      'Totaler på tværs af alle sider vises i denne valuta. Du kan ændre den senere i Indstillinger.';

  @override
  String get onboardingGetStarted => 'Kom i gang';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Lyst';

  @override
  String get themeDark => 'Mørkt';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDanish => 'Dansk';

  @override
  String get dashboardTitle => 'Overblik';

  @override
  String get dashboardNetResult => 'Nettoresultat';

  @override
  String get dashboardProfit => 'Overskud';

  @override
  String get dashboardLoss => 'Tab';

  @override
  String get dashboardBreakEven => 'Balance';

  @override
  String get dashboardTotalDeposited => 'Indbetalt';

  @override
  String get dashboardTotalWithdrawn => 'Udbetalt';

  @override
  String get dashboardProfitOverTime => 'Udvikling over tid';

  @override
  String get dashboardYourSites => 'Dine sider';

  @override
  String get dashboardSeeAll => 'Se alle';

  @override
  String get dashboardEmptyTitle => 'Intet registreret endnu';

  @override
  String get dashboardEmptyBody =>
      'Tilføj din første ind- eller udbetaling, så viser BetBook dig ærligt, hvor du står.';

  @override
  String get dashboardAddSite => 'Tilføj en side';

  @override
  String get dashboardAllTime => 'Al tid';

  @override
  String get dashboardUpOverall => 'Du er i plus samlet set';

  @override
  String get dashboardDownOverall => 'Du er i minus samlet set';

  @override
  String get dashboardEvenOverall => 'Du går i nul';

  @override
  String get allDataOnDevice => 'Alle data bliver på din enhed';

  @override
  String get sitesEmptyTitle => 'Ingen spillesteder endnu';

  @override
  String get sitesEmptyBody =>
      'Tilføj det første sted, du spiller på, så du kan følge dine ind- og udbetalinger.';

  @override
  String get siteDetailEmptyTitle => 'Ingen transaktioner her endnu';

  @override
  String get siteDetailEmptyBody =>
      'Spillestedet er oprettet. Tilføj den første ind- eller udbetaling for at starte.';

  @override
  String get commonCurrency => 'Valuta';

  @override
  String get txSaveTransaction => 'Gem transaktion';

  @override
  String txRunningNet(String amount) {
    return 'netto $amount';
  }

  @override
  String get sitesTitle => 'Sider';

  @override
  String get siteAdd => 'Tilføj side';

  @override
  String get siteEdit => 'Rediger side';

  @override
  String get siteNameLabel => 'Sidens navn';

  @override
  String get siteNameHint => 'f.eks. Bet365, Unibet…';

  @override
  String get siteCurrencyLabel => 'Valuta';

  @override
  String get siteColorLabel => 'Farve';

  @override
  String get siteDelete => 'Slet side';

  @override
  String get siteDeleteConfirm =>
      'Slet denne side og alle dens transaktioner? Dette kan ikke fortrydes.';

  @override
  String get siteNet => 'Netto';

  @override
  String sitesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spillesteder',
      one: '1 spillested',
      zero: 'Ingen spillesteder',
    );
    return '$_temp0';
  }

  @override
  String get siteEmptyTransactions => 'Ingen transaktioner endnu';

  @override
  String siteTransactionCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transaktioner',
      one: '1 transaktion',
      zero: 'Ingen transaktioner',
    );
    return '$_temp0';
  }

  @override
  String get txAdd => 'Tilføj transaktion';

  @override
  String get txEdit => 'Rediger transaktion';

  @override
  String get txTypeDeposit => 'Indbetaling';

  @override
  String get txTypeWithdrawal => 'Udbetaling';

  @override
  String get txAmount => 'Beløb';

  @override
  String get txDate => 'Dato';

  @override
  String get txSite => 'Side';

  @override
  String get txSelectSite => 'Vælg en side';

  @override
  String get txNote => 'Note';

  @override
  String get txNoteHint => 'Valgfri note';

  @override
  String get txDelete => 'Slet transaktion';

  @override
  String get txDeleteConfirm =>
      'Slet denne transaktion? Dette kan ikke fortrydes.';

  @override
  String get txAmountError => 'Indtast et beløb større end nul';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsRangeLast7 => '7 dage';

  @override
  String get statsRangeLast30 => '30 dage';

  @override
  String get statsRangeLast90 => '90 dage';

  @override
  String get statsRangeYear => 'I år';

  @override
  String get statsRangeAll => 'Al tid';

  @override
  String get statsNetResult => 'Nettoresultat';

  @override
  String get statsByMonth => 'Pr. måned';

  @override
  String get statsBySite => 'Pr. side';

  @override
  String get statsBestSite => 'Bedste side';

  @override
  String get statsWorstSite => 'Værste side';

  @override
  String get statsNoData => 'Ikke nok data endnu';

  @override
  String get statsNoDataBody =>
      'Tilføj et par transaktioner for at se dine tendenser her.';

  @override
  String get settingsTitle => 'Indstillinger';

  @override
  String get settingsSectionGeneral => 'Generelt';

  @override
  String get settingsSectionSecurity => 'Sikkerhed';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsSectionResponsible => 'Ansvarligt spil';

  @override
  String get settingsSectionAbout => 'Om';

  @override
  String get settingsLanguage => 'Sprog';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get settingsBaseCurrency => 'Hovedvaluta';

  @override
  String get settingsExchangeRates => 'Valutakurser';

  @override
  String get settingsAppLock => 'App-lås';

  @override
  String get settingsAppLockSubtitle =>
      'Kræv biometri eller PIN for at åbne appen';

  @override
  String get settingsBiometric => 'Brug biometri';

  @override
  String get settingsChangePin => 'Skift PIN';

  @override
  String get settingsSetPin => 'Vælg en PIN';

  @override
  String get settingsExport => 'Eksportér backup';

  @override
  String get settingsExportSubtitle => 'Gem alle dine data i en fil';

  @override
  String get settingsImport => 'Importér backup';

  @override
  String get settingsImportSubtitle => 'Gendan data fra en backup-fil';

  @override
  String get settingsClearData => 'Ryd alle data';

  @override
  String get settingsClearDataSubtitle => 'Slet alt på denne enhed permanent';

  @override
  String get settingsClearDataConfirm =>
      'Dette sletter alle sider og transaktioner permanent. Overvej at eksportere en backup først. Fortsæt?';

  @override
  String get settingsVersion => 'Version';

  @override
  String get settingsLicenses => 'Open source-licenser';

  @override
  String get settingsPrivacy => 'Privatliv';

  @override
  String get settingsPrivacyBody =>
      'BetBook gemmer alle dine data lokalt på denne enhed. Intet uploades, deles eller spores. Hav en backup, så du ikke mister din historik.';

  @override
  String get exchangeRatesTitle => 'Valutakurser';

  @override
  String exchangeRatesBody(String base) {
    return 'Kurserne omregner hver sides valuta til din hovedvaluta ($base) i totaler. Ret dem, så de passer med dine egne tal.';
  }

  @override
  String get exchangeRatesAddCurrency => 'Tilføj valuta';

  @override
  String get exchangeRatesCustom => 'Anden valuta…';

  @override
  String get exchangeRatesCustomCode => '3-bogstavskode (f.eks. JPY)';

  @override
  String get exchangeRatesCodeInvalid => 'Indtast en valutakode på 3 bogstaver';

  @override
  String get exchangeRatesCodeTaken => 'Den valuta findes allerede';

  @override
  String exchangeRatesOneBase(String base) {
    return '1 $base =';
  }

  @override
  String get exchangeRatesBaseRow => 'Hovedvaluta';

  @override
  String get ratesAutoUpdate => 'Opdatér kurser ugentligt';

  @override
  String get ratesAutoUpdateSubtitle =>
      'Hent offentlige referencekurser (ECB) automatisk';

  @override
  String get ratesRefreshNow => 'Opdatér kurser nu';

  @override
  String ratesLastUpdated(String date) {
    return 'Sidst opdateret: $date';
  }

  @override
  String get ratesNever => 'aldrig';

  @override
  String get ratesUpdated => 'Kurser opdateret';

  @override
  String get ratesUpdateFailed =>
      'Kunne ikke opdatere kurser. Tjek din forbindelse.';

  @override
  String get lockTitle => 'BetBook er låst';

  @override
  String get lockUnlock => 'Lås op';

  @override
  String get lockUseBiometrics => 'Lås op med biometri';

  @override
  String get lockInstruction => 'Brug fingeraftryk eller indtast din pinkode';

  @override
  String get lockEnterPin => 'Indtast din PIN';

  @override
  String get lockSetPin => 'Vælg en PIN';

  @override
  String get lockConfirmPin => 'Bekræft din PIN';

  @override
  String get lockPinMismatch => 'PIN-koderne matcher ikke, prøv igen';

  @override
  String get lockWrongPin => 'Forkert PIN';

  @override
  String get lockForgotPin => 'Glemt PIN?';

  @override
  String get rgTitle => 'Ansvarligt spil';

  @override
  String get rgIntro =>
      'Disse valgfrie værktøjer hjælper dig med at bevare kontrollen. BetBook holder kun styr på penge — det opfordrer aldrig til at spille.';

  @override
  String get rgDepositLimit => 'Indbetalingsgrænse';

  @override
  String get rgDepositLimitSubtitle =>
      'Bliv advaret, når indbetalinger overstiger en grænse';

  @override
  String get rgNetLossAlert => 'Advarsel ved nettotab';

  @override
  String get rgNetLossAlertSubtitle =>
      'Bliv advaret, når dit nettotab overstiger et beløb';

  @override
  String get rgPeriodDaily => 'Dagligt';

  @override
  String get rgPeriodWeekly => 'Ugentligt';

  @override
  String get rgPeriodMonthly => 'Månedligt';

  @override
  String get rgLimitAmount => 'Grænsebeløb';

  @override
  String rgExceededDeposit(String period, String amount) {
    return 'Du har overskredet din indbetalingsgrænse ($period) på $amount.';
  }

  @override
  String rgExceededLoss(String amount) {
    return 'Dit nettotab har overskredet $amount.';
  }

  @override
  String get rgHelpTitle => 'Har du brug for at tale med nogen?';

  @override
  String get rgHelpBody =>
      'Hvis spil ikke længere er sjovt, findes der hjælp. I Danmark kan du ringe til StopSpillet på 70 22 28 25.';

  @override
  String get backupExportSuccess => 'Backup gemt';

  @override
  String get backupImportSuccess => 'Backup importeret';

  @override
  String get backupImportConfirm =>
      'Import erstatter alle nuværende data med backuppens indhold. Fortsæt?';

  @override
  String get backupInvalidFile => 'Filen er ikke en gyldig BetBook-backup';

  @override
  String quickAddDatedNow(String time) {
    return 'Dateres nu · i dag $time';
  }

  @override
  String get quickAddSaved => 'Postering gemt';

  @override
  String get repeatEntry => 'Gentag postering';

  @override
  String get repeatThisEntry => 'Gentag denne postering';

  @override
  String get reminders => 'Påmindelser';

  @override
  String get limitWarnings => 'Advarsler om grænser';

  @override
  String get limitWarningsSub => 'Ved 80% og 100% af din indbetalingsgrænse';

  @override
  String get setLimitFirst => 'Sæt en grænse først';

  @override
  String get notifRationaleTitle => 'Påmindelser på din telefon';

  @override
  String get notifRationaleBody =>
      'BetBook laver påmindelserne på din telefon. Intet sendes til en server, og der er ingen konto.';

  @override
  String get notNow => 'Ikke nu';

  @override
  String get continueLabel => 'Fortsæt';

  @override
  String get notifDisabledSystem =>
      'Påmindelser er slået fra i systemindstillinger.';

  @override
  String get openSettings => 'Åbn indstillinger';

  @override
  String get limitChannelName => 'Advarsler om grænser';

  @override
  String get limitChannelDesc =>
      'Når du nærmer dig eller når en grænse, du har sat';

  @override
  String get limitPeriodDay => 'dag';

  @override
  String get limitPeriodWeek => 'uge';

  @override
  String get limitPeriodMonth => 'måned';

  @override
  String get limitApproachTitle => 'Du har brugt 80% af din indbetalingsgrænse';

  @override
  String limitApproachBody(String used, String limit, String period) {
    return '$used af $limit denne $period. Din grænse ligger i Indstillinger, hvis du vil ændre den.';
  }

  @override
  String get limitReachedTitle => 'Du har nået din indbetalingsgrænse';

  @override
  String limitReachedBody(String used, String limit, String period) {
    return '$used af $limit denne $period. Tag en pause eller ændr din grænse — begge findes i Indstillinger.';
  }

  @override
  String netLossTitle(String amount) {
    return 'Dit nettotab er over $amount';
  }

  @override
  String get netLossBody =>
      'Det er den grænse, du har sat. Tryk for at se dine grænser.';

  @override
  String limitUsedPct(int pct) {
    return '$pct% af din grænse brugt';
  }

  @override
  String get limitReachedLabel => 'Din grænse er nået';

  @override
  String get netLossLabel => 'Din nettotabsgrænse';

  @override
  String limitFigureLine(String used, String limit, String period) {
    return '$used af $limit denne $period';
  }

  @override
  String get adjust => 'Justér';

  @override
  String get takeABreak => 'Tag en pause';

  @override
  String get takeABreakSub => 'Skjul totaler og pause påmindelser';

  @override
  String get takeABreakDesc =>
      'Totaler skjules, og påmindelser sættes på pause. Du kan stadig registrere, og du kan afslutte pausen når som helst.';

  @override
  String get breakOption24h => '24 timer';

  @override
  String get breakOption1week => '1 uge';

  @override
  String get breakOption1month => '1 måned';

  @override
  String breakUntil(String date) {
    return 'Pause indtil $date';
  }

  @override
  String get endBreak => 'Afslut pause';

  @override
  String get showTotals => 'Vis totaler';

  @override
  String get settingsImportCsv => 'Importér CSV';

  @override
  String get settingsImportCsvSubtitle => 'Tilføj transaktioner fra en CSV-fil';

  @override
  String get csvImportConfirm =>
      'Transaktioner i filen føjes til dine nuværende data. Sider matches på navn og oprettes hvis de mangler.';

  @override
  String csvImportAdded(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transaktioner tilføjet',
      one: '1 transaktion tilføjet',
    );
    return '$_temp0';
  }

  @override
  String csvImportSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rækker sprunget over',
      one: '1 række sprunget over',
    );
    return '$_temp0';
  }

  @override
  String get toastSaved => 'Gemt';

  @override
  String get toastDeleted => 'Slettet';
}
