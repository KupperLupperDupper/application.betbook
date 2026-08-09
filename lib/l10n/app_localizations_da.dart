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
  String get dashboardEmptyTitle => 'Ingen sider endnu';

  @override
  String get dashboardEmptyBody =>
      'Tilføj din første spilside for at begynde at følge dit overskud og tab.';

  @override
  String get dashboardAddSite => 'Tilføj en side';

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
  String get toastSaved => 'Gemt';

  @override
  String get toastDeleted => 'Slettet';
}
