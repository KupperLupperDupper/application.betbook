import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../core/money/money_format.dart';
import '../core/stats/responsible_gambling.dart';
import '../core/stats/summaries.dart';
import '../data/models/enums.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import 'data_providers.dart';
import 'settings_providers.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

/// Last week's net P/L (base currency) and how many sites were active.
class WeeklySummary {
  const WeeklySummary({
    required this.netBase,
    required this.siteCount,
    required this.hasActivity,
  });
  final double netBase;
  final int siteCount;
  final bool hasActivity;
}

/// ISO date (`YYYY-MM-DD`) of a day, used as a stable week/period key.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// The Monday of the current week — the key for the weekly card's dismissal.
String currentWeekIso(DateTime now) =>
    isoDate(periodStart(LimitPeriod.weekly, now));

/// Net P/L + active-site count for the calendar week that just ended.
final weeklySummaryProvider = Provider<WeeklySummary>((ref) {
  final sites = ref.watch(sitesProvider).valueOrNull ?? const [];
  final txs = ref.watch(allTransactionsProvider).valueOrNull ?? const [];
  final rates = ref.watch(rateMapProvider);
  final base = ref.watch(settingsProvider.select((s) => s.baseCurrency));

  final thisMonday = periodStart(LimitPeriod.weekly, DateTime.now());
  final lastMonday = thisMonday.subtract(const Duration(days: 7));
  final currencyBySite = {for (final s in sites) s.id: s.currencyCode};

  var net = 0.0;
  final activeSites = <String>{};
  for (final t in txs) {
    if (t.date.isBefore(lastMonday) || !t.date.isBefore(thisMonday)) continue;
    final b = convertMinorToBase(
        t.amountMinor, currencyBySite[t.siteId] ?? base, rates);
    net += t.type == TransactionType.deposit ? -b : b;
    activeSites.add(t.siteId);
  }
  return WeeklySummary(
    netBase: net,
    siteCount: activeSites.length,
    hasActivity: activeSites.isNotEmpty,
  );
});

String _periodWord(AppLocalizations l10n, LimitPeriod p) => switch (p) {
      LimitPeriod.daily => l10n.limitPeriodDay,
      LimitPeriod.weekly => l10n.limitPeriodWeek,
      LimitPeriod.monthly => l10n.limitPeriodMonth,
    };

/// Fires the OS limit warnings for first crossings this period (§1.2). Fired on
/// transaction commit (via the rgStatus listener) and on app resume. No-ops when
/// warnings are off, a break is active, or the crossing already fired.
Future<void> maybeFireLimitWarnings(WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  if (!settings.limitWarningsEnabled || settings.breakActive) return;

  final rg = ref.read(rgStatusProvider);
  if (!rg.anyExceeded &&
      !(rg.depositLimitBase > 0 &&
          rg.periodDepositBase >= 0.8 * rg.depositLimitBase)) {
    return;
  }

  final l10n = lookupAppLocalizations(Locale(settings.languageCode));
  final lang = settings.languageCode;
  final base = settings.baseCurrency;
  final service = ref.read(notificationServiceProvider);
  final periodKey = isoDate(periodStart(rg.period, DateTime.now()));
  final periodWord = _periodWord(l10n, rg.period);
  String money(double v) => formatMajor(v, base, localeName: lang);

  // Approaching (≥80%, not yet reached).
  if (rg.depositLimitBase > 0 &&
      !rg.depositLimitExceeded &&
      rg.periodDepositBase >= 0.8 * rg.depositLimitBase &&
      settings.rgApproachKey != periodKey) {
    await service.showLimit(
      slot: 0,
      channelName: l10n.limitChannelName,
      channelDesc: l10n.limitChannelDesc,
      title: l10n.limitApproachTitle,
      body: l10n.limitApproachBody(
          money(rg.periodDepositBase), money(rg.depositLimitBase), periodWord),
      payload: Routes.responsibleGambling,
    );
    await ref.read(settingsProvider.notifier).setRgNotifiedKeys(approach: periodKey);
  }

  // Reached (≥100%).
  if (rg.depositLimitExceeded && settings.rgReachedKey != periodKey) {
    await service.showLimit(
      slot: 1,
      channelName: l10n.limitChannelName,
      channelDesc: l10n.limitChannelDesc,
      title: l10n.limitReachedTitle,
      body: l10n.limitReachedBody(
          money(rg.periodDepositBase), money(rg.depositLimitBase), periodWord),
      payload: Routes.responsibleGambling,
    );
    await ref.read(settingsProvider.notifier).setRgNotifiedKeys(reached: periodKey);
  }

  // Net-loss alert.
  if (rg.netLossExceeded && settings.rgNetLossKey != periodKey) {
    await service.showLimit(
      slot: 2,
      channelName: l10n.limitChannelName,
      channelDesc: l10n.limitChannelDesc,
      title: l10n.netLossTitle(money(rg.netLossLimitBase)),
      body: l10n.netLossBody,
      payload: Routes.responsibleGambling,
    );
    await ref.read(settingsProvider.notifier).setRgNotifiedKeys(netLoss: periodKey);
  }
}

/// (Re)registers or cancels the weekly Monday-09:00 nudge to match settings.
/// Called on launch, on toggling weekly summary, and when a break starts/ends.
Future<void> syncWeeklySchedule(WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  final service = ref.read(notificationServiceProvider);
  if (settings.weeklySummaryEnabled && !settings.breakActive) {
    final l10n = lookupAppLocalizations(Locale(settings.languageCode));
    await service.scheduleWeekly(
      channelName: l10n.weeklyChannelName,
      channelDesc: l10n.weeklyChannelDesc,
      title: l10n.weeklySummary,
      body: l10n.weeklyNudgeBody,
      payload: Routes.home,
    );
  } else {
    await service.cancelWeekly();
  }
}
