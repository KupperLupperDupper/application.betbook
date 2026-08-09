import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/stats/responsible_gambling.dart';
import '../core/stats/summaries.dart';
import '../data/database/database.dart';
import 'core_providers.dart';
import 'settings_providers.dart';

/// All sites, ordered for display.
final sitesProvider = StreamProvider<List<Site>>(
  (ref) => ref.watch(siteRepositoryProvider).watchSites(),
);

/// A single site by id (null once deleted).
final siteByIdProvider = StreamProvider.family<Site?, String>(
  (ref, id) => ref.watch(siteRepositoryProvider).watchSite(id),
);

/// Every transaction, newest first.
final allTransactionsProvider = StreamProvider<List<Transaction>>(
  (ref) => ref.watch(transactionRepositoryProvider).watchAll(),
);

/// Transactions for one site, newest first.
final siteTransactionsProvider =
    StreamProvider.family<List<Transaction>, String>(
  (ref, siteId) => ref.watch(transactionRepositoryProvider).watchForSite(siteId),
);

/// All editable exchange rates.
final ratesProvider = StreamProvider<List<ExchangeRate>>(
  (ref) => ref.watch(databaseProvider).watchRates(),
);

/// Currency code → rate-to-base, derived from [ratesProvider].
final rateMapProvider = Provider<Map<String, double>>((ref) {
  final rates = ref.watch(ratesProvider).valueOrNull ?? const [];
  return {for (final r in rates) r.currencyCode: r.rateToBase};
});

/// The computed portfolio (per-site summaries + base-currency totals), or null
/// while the underlying streams are still loading.
final portfolioProvider = Provider<PortfolioData?>((ref) {
  final sites = ref.watch(sitesProvider).valueOrNull;
  final txs = ref.watch(allTransactionsProvider).valueOrNull;
  if (sites == null || txs == null) return null;

  return computePortfolio(
    sites: sites,
    transactions: txs,
    rateToBase: ref.watch(rateMapProvider),
    baseCurrency: ref.watch(settingsProvider.select((s) => s.baseCurrency)),
  );
});

/// Live responsible-gambling status against the user's configured limits.
final rgStatusProvider = Provider<RgStatus>((ref) {
  final settings = ref.watch(settingsProvider);
  if (!settings.depositLimitEnabled && !settings.netLossAlertEnabled) {
    return RgStatus.none;
  }
  final sites = ref.watch(sitesProvider).valueOrNull;
  final txs = ref.watch(allTransactionsProvider).valueOrNull;
  if (sites == null || txs == null) return RgStatus.none;

  return evaluateResponsibleGambling(
    sites: sites,
    transactions: txs,
    rateToBase: ref.watch(rateMapProvider),
    baseCurrency: settings.baseCurrency,
    now: DateTime.now(),
    depositLimitEnabled: settings.depositLimitEnabled,
    depositLimitMinor: settings.depositLimitMinor,
    depositLimitPeriod: settings.depositLimitPeriod,
    netLossAlertEnabled: settings.netLossAlertEnabled,
    netLossAlertMinor: settings.netLossAlertMinor,
  );
});
