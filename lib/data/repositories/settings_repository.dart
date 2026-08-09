import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';
import '../models/enums.dart';

/// Reads and writes [AppSettings] to [SharedPreferences].
///
/// Sensitive values (the app-lock PIN) live in secure storage instead; this
/// only holds non-secret preferences.
class SettingsRepository {
  SettingsRepository(this._prefs);

  final SharedPreferences _prefs;

  static const _kTheme = 'settings.themeMode';
  static const _kLanguage = 'settings.languageCode';
  static const _kBaseCurrency = 'settings.baseCurrency';
  static const _kOnboarding = 'settings.onboardingComplete';
  static const _kAppLock = 'settings.appLockEnabled';
  static const _kBiometric = 'settings.biometricEnabled';
  static const _kDepositLimitEnabled = 'settings.depositLimitEnabled';
  static const _kDepositLimitMinor = 'settings.depositLimitMinor';
  static const _kDepositLimitPeriod = 'settings.depositLimitPeriod';
  static const _kNetLossEnabled = 'settings.netLossAlertEnabled';
  static const _kNetLossMinor = 'settings.netLossAlertMinor';
  static const _kRatesAutoUpdate = 'settings.ratesAutoUpdate';
  static const _kRatesLastFetched = 'settings.ratesLastFetchedMillis';

  AppSettings load() {
    return AppSettings(
      themeMode: _themeFromString(_prefs.getString(_kTheme)),
      languageCode: _prefs.getString(_kLanguage) ?? 'en',
      baseCurrency: _prefs.getString(_kBaseCurrency) ?? 'DKK',
      onboardingComplete: _prefs.getBool(_kOnboarding) ?? false,
      appLockEnabled: _prefs.getBool(_kAppLock) ?? false,
      biometricEnabled: _prefs.getBool(_kBiometric) ?? false,
      depositLimitEnabled: _prefs.getBool(_kDepositLimitEnabled) ?? false,
      depositLimitMinor: _prefs.getInt(_kDepositLimitMinor) ?? 0,
      depositLimitPeriod:
          _periodFromString(_prefs.getString(_kDepositLimitPeriod)),
      netLossAlertEnabled: _prefs.getBool(_kNetLossEnabled) ?? false,
      netLossAlertMinor: _prefs.getInt(_kNetLossMinor) ?? 0,
      ratesAutoUpdate: _prefs.getBool(_kRatesAutoUpdate) ?? false,
      ratesLastFetchedMillis: _prefs.getInt(_kRatesLastFetched) ?? 0,
    );
  }

  Future<void> save(AppSettings s) async {
    await _prefs.setString(_kTheme, s.themeMode.name);
    await _prefs.setString(_kLanguage, s.languageCode);
    await _prefs.setString(_kBaseCurrency, s.baseCurrency);
    await _prefs.setBool(_kOnboarding, s.onboardingComplete);
    await _prefs.setBool(_kAppLock, s.appLockEnabled);
    await _prefs.setBool(_kBiometric, s.biometricEnabled);
    await _prefs.setBool(_kDepositLimitEnabled, s.depositLimitEnabled);
    await _prefs.setInt(_kDepositLimitMinor, s.depositLimitMinor);
    await _prefs.setString(_kDepositLimitPeriod, s.depositLimitPeriod.name);
    await _prefs.setBool(_kNetLossEnabled, s.netLossAlertEnabled);
    await _prefs.setInt(_kNetLossMinor, s.netLossAlertMinor);
    await _prefs.setBool(_kRatesAutoUpdate, s.ratesAutoUpdate);
    await _prefs.setInt(_kRatesLastFetched, s.ratesLastFetchedMillis);
  }

  ThemeMode _themeFromString(String? value) {
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  LimitPeriod _periodFromString(String? value) {
    return switch (value) {
      'daily' => LimitPeriod.daily,
      'weekly' => LimitPeriod.weekly,
      _ => LimitPeriod.monthly,
    };
  }
}
