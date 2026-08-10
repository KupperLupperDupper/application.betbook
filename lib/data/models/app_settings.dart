import 'package:flutter/material.dart';

import 'enums.dart';

/// All user preferences, held in SharedPreferences. Immutable value type.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.languageCode = 'en',
    this.baseCurrency = 'DKK',
    this.onboardingComplete = false,
    this.appLockEnabled = false,
    this.biometricEnabled = false,
    this.depositLimitEnabled = false,
    this.depositLimitMinor = 0,
    this.depositLimitPeriod = LimitPeriod.monthly,
    this.netLossAlertEnabled = false,
    this.netLossAlertMinor = 0,
    this.ratesAutoUpdate = false,
    this.ratesLastFetchedMillis = 0,
    this.limitWarningsEnabled = false,
    this.notifRationaleShown = false,
    this.rgApproachKey = '',
    this.rgReachedKey = '',
    this.rgNetLossKey = '',
    this.breakUntilMillis = 0,
  });

  final ThemeMode themeMode;
  final String languageCode;
  final String baseCurrency;
  final bool onboardingComplete;

  final bool appLockEnabled;
  final bool biometricEnabled;

  final bool depositLimitEnabled;
  final int depositLimitMinor;
  final LimitPeriod depositLimitPeriod;
  final bool netLossAlertEnabled;
  final int netLossAlertMinor;

  /// Whether to auto-refresh FX rates weekly from the public rate service.
  final bool ratesAutoUpdate;

  /// Epoch millis of the last successful rate fetch (0 = never).
  final int ratesLastFetchedMillis;

  // ── Reminders (opt-in local notifications) ────────────────────────────────
  final bool limitWarningsEnabled;

  /// The notification-permission rationale sheet is shown once per install.
  final bool notifRationaleShown;

  /// Period-start keys (`YYYY-MM-DD`) for which each limit warning already
  /// fired, so it fires at most once per period. Empty = not yet fired.
  final String rgApproachKey;
  final String rgReachedKey;
  final String rgNetLossKey;

  /// Epoch millis until which a "take a break" is active (0 = no break).
  final int breakUntilMillis;

  Locale get locale => Locale(languageCode);

  DateTime? get breakUntil =>
      breakUntilMillis == 0 ? null : DateTime.fromMillisecondsSinceEpoch(breakUntilMillis);

  /// True while a break is active (totals hidden, reminders paused).
  bool get breakActive =>
      breakUntil != null && breakUntil!.isAfter(DateTime.now());

  DateTime? get ratesLastFetched => ratesLastFetchedMillis == 0
      ? null
      : DateTime.fromMillisecondsSinceEpoch(ratesLastFetchedMillis);

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? languageCode,
    String? baseCurrency,
    bool? onboardingComplete,
    bool? appLockEnabled,
    bool? biometricEnabled,
    bool? depositLimitEnabled,
    int? depositLimitMinor,
    LimitPeriod? depositLimitPeriod,
    bool? netLossAlertEnabled,
    int? netLossAlertMinor,
    bool? ratesAutoUpdate,
    int? ratesLastFetchedMillis,
    bool? limitWarningsEnabled,
    bool? notifRationaleShown,
    String? rgApproachKey,
    String? rgReachedKey,
    String? rgNetLossKey,
    int? breakUntilMillis,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      languageCode: languageCode ?? this.languageCode,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      depositLimitEnabled: depositLimitEnabled ?? this.depositLimitEnabled,
      depositLimitMinor: depositLimitMinor ?? this.depositLimitMinor,
      depositLimitPeriod: depositLimitPeriod ?? this.depositLimitPeriod,
      netLossAlertEnabled: netLossAlertEnabled ?? this.netLossAlertEnabled,
      netLossAlertMinor: netLossAlertMinor ?? this.netLossAlertMinor,
      ratesAutoUpdate: ratesAutoUpdate ?? this.ratesAutoUpdate,
      ratesLastFetchedMillis:
          ratesLastFetchedMillis ?? this.ratesLastFetchedMillis,
      limitWarningsEnabled: limitWarningsEnabled ?? this.limitWarningsEnabled,
      notifRationaleShown: notifRationaleShown ?? this.notifRationaleShown,
      rgApproachKey: rgApproachKey ?? this.rgApproachKey,
      rgReachedKey: rgReachedKey ?? this.rgReachedKey,
      rgNetLossKey: rgNetLossKey ?? this.rgNetLossKey,
      breakUntilMillis: breakUntilMillis ?? this.breakUntilMillis,
    );
  }
}
