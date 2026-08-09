import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/money/currency.dart';
import '../data/database/database.dart';
import '../data/repositories/fx_rate_service.dart';
import 'core_providers.dart';
import 'settings_providers.dart';

final fxRateServiceProvider = Provider<FxRateService>((ref) => FxRateService());

/// Outcome of a rate refresh attempt, for surfacing in the UI.
enum RatesRefreshResult { success, failure, skipped }

/// Fetches public FX rates and writes them into the exchange-rates table.
class RatesUpdater {
  RatesUpdater(this._ref);
  final Ref _ref;

  /// Refreshes rates for the base currency now. Returns whether it succeeded.
  Future<RatesRefreshResult> refreshNow() async {
    final settings = _ref.read(settingsProvider);
    final db = _ref.read(databaseProvider);
    final service = _ref.read(fxRateServiceProvider);

    // Fetch for every currency the app knows about, so newly added sites are
    // covered even before they have a rate row.
    final symbols = kSupportedCurrencies.map((c) => c.code).toList();

    try {
      final rates = await service.fetchRatesToBase(
        base: settings.baseCurrency,
        symbols: symbols,
      );
      if (rates.isEmpty) return RatesRefreshResult.failure;

      final now = DateTime.now();
      for (final entry in rates.entries) {
        await db.upsertRate(
          ExchangeRatesCompanion(
            currencyCode: Value(entry.key),
            rateToBase: Value(entry.value),
            updatedAt: Value(now),
          ),
        );
      }
      // Keep the base currency pinned at 1.0.
      await db.upsertRate(
        ExchangeRatesCompanion(
          currencyCode: Value(settings.baseCurrency),
          rateToBase: const Value(1.0),
          updatedAt: Value(now),
        ),
      );
      await _ref.read(settingsProvider.notifier).markRatesFetched(now);
      return RatesRefreshResult.success;
    } catch (_) {
      return RatesRefreshResult.failure;
    }
  }

  /// Refreshes only when auto-update is on and it's been ≥ 7 days.
  Future<RatesRefreshResult> maybeAutoRefresh() async {
    final settings = _ref.read(settingsProvider);
    if (!settings.ratesAutoUpdate) return RatesRefreshResult.skipped;
    final last = settings.ratesLastFetched;
    if (last != null &&
        DateTime.now().difference(last) < const Duration(days: 7)) {
      return RatesRefreshResult.skipped;
    }
    return refreshNow();
  }
}

final ratesUpdaterProvider =
    Provider<RatesUpdater>((ref) => RatesUpdater(ref));
