import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/routes.dart';
import '../core/money/money_format.dart';
import '../core/stats/responsible_gambling.dart';
import '../data/models/enums.dart';
import '../l10n/app_localizations.dart';
import '../services/notification_service.dart';
import 'data_providers.dart';
import 'settings_providers.dart';

final notificationServiceProvider =
    Provider<NotificationService>((ref) => NotificationService.instance);

/// ISO date (`YYYY-MM-DD`) of a day, used as a stable period key.
String isoDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

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
