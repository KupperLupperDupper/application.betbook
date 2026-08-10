import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/app_settings.dart';
import '../data/models/enums.dart';
import 'core_providers.dart';

/// Holds and mutates the user's [AppSettings]. Every setter persists to
/// SharedPreferences and then updates state so the UI reacts immediately.
class SettingsController extends Notifier<AppSettings> {
  @override
  AppSettings build() {
    return ref.watch(settingsRepositoryProvider).load();
  }

  Future<void> _update(AppSettings next) async {
    state = next;
    await ref.read(settingsRepositoryProvider).save(next);
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _update(state.copyWith(themeMode: mode));

  Future<void> setLanguage(String languageCode) =>
      _update(state.copyWith(languageCode: languageCode));

  Future<void> setBaseCurrency(String code) =>
      _update(state.copyWith(baseCurrency: code));

  Future<void> completeOnboarding() =>
      _update(state.copyWith(onboardingComplete: true));

  Future<void> setAppLockEnabled(bool enabled) => _update(
        state.copyWith(
          appLockEnabled: enabled,
          // Disabling the lock also drops biometrics.
          biometricEnabled: enabled ? state.biometricEnabled : false,
        ),
      );

  Future<void> setBiometricEnabled(bool enabled) =>
      _update(state.copyWith(biometricEnabled: enabled));

  Future<void> setDepositLimit({
    required bool enabled,
    int? amountMinor,
    LimitPeriod? period,
  }) =>
      _update(state.copyWith(
        depositLimitEnabled: enabled,
        depositLimitMinor: amountMinor,
        depositLimitPeriod: period,
      ));

  Future<void> setNetLossAlert({required bool enabled, int? amountMinor}) =>
      _update(state.copyWith(
        netLossAlertEnabled: enabled,
        netLossAlertMinor: amountMinor,
      ));

  Future<void> setRatesAutoUpdate(bool enabled) =>
      _update(state.copyWith(ratesAutoUpdate: enabled));

  Future<void> markRatesFetched(DateTime when) =>
      _update(state.copyWith(ratesLastFetchedMillis: when.millisecondsSinceEpoch));

  // ── Reminders ─────────────────────────────────────────────────────────────
  Future<void> setLimitWarningsEnabled(bool enabled) =>
      _update(state.copyWith(limitWarningsEnabled: enabled));

  Future<void> markNotifRationaleShown() =>
      _update(state.copyWith(notifRationaleShown: true));

  Future<void> setRgNotifiedKeys({
    String? approach,
    String? reached,
    String? netLoss,
  }) =>
      _update(state.copyWith(
        rgApproachKey: approach,
        rgReachedKey: reached,
        rgNetLossKey: netLoss,
      ));

  /// Starts a break lasting [duration] from now (totals hidden, reminders
  /// paused). Pass [Duration.zero] via [endBreak] to end early.
  Future<void> startBreak(Duration duration) => _update(state.copyWith(
        breakUntilMillis:
            DateTime.now().add(duration).millisecondsSinceEpoch,
      ));

  Future<void> endBreak() => _update(state.copyWith(breakUntilMillis: 0));
}

final settingsProvider =
    NotifierProvider<SettingsController, AppSettings>(SettingsController.new);
