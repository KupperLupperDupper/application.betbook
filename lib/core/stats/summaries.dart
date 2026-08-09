import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../money/money_format.dart';

/// Aggregated totals for a single site, in that site's own currency.
class SiteSummary {
  const SiteSummary({
    required this.siteId,
    required this.currencyCode,
    required this.depositedMinor,
    required this.withdrawnMinor,
    required this.transactionCount,
  });

  final String siteId;
  final String currencyCode;
  final int depositedMinor;
  final int withdrawnMinor;
  final int transactionCount;

  /// Net result in the site's currency (minor units): withdrawals − deposits.
  int get netMinor => withdrawnMinor - depositedMinor;
}

/// The whole picture, with per-site detail and base-currency totals.
class PortfolioData {
  const PortfolioData({
    required this.baseCurrency,
    required this.siteSummaries,
    required this.depositedBase,
    required this.withdrawnBase,
    required this.transactionCount,
  });

  final String baseCurrency;
  final Map<String, SiteSummary> siteSummaries;
  final double depositedBase;
  final double withdrawnBase;
  final int transactionCount;

  /// Net result across all sites, converted to the base currency.
  double get netBase => withdrawnBase - depositedBase;

  bool get isEmpty => transactionCount == 0;
}

/// Value of `1` unit of [currency] in the base currency. Falls back to `1.0`
/// (treat as base) when a rate is missing, which is always safe.
double _rate(Map<String, double> rateToBase, String currency) =>
    rateToBase[currency] ?? 1.0;

/// Converts an amount in [currency] minor units into base-currency major units.
double convertMinorToBase(
  int minor,
  String currency,
  Map<String, double> rateToBase,
) {
  return minorToMajor(minor) * _rate(rateToBase, currency);
}

PortfolioData computePortfolio({
  required List<Site> sites,
  required List<Transaction> transactions,
  required Map<String, double> rateToBase,
  required String baseCurrency,
}) {
  final currencyBySite = {for (final s in sites) s.id: s.currencyCode};
  final summaries = <String, SiteSummary>{
    for (final s in sites)
      s.id: SiteSummary(
        siteId: s.id,
        currencyCode: s.currencyCode,
        depositedMinor: 0,
        withdrawnMinor: 0,
        transactionCount: 0,
      ),
  };

  for (final tx in transactions) {
    final existing = summaries[tx.siteId];
    if (existing == null) continue; // orphan guard
    summaries[tx.siteId] = SiteSummary(
      siteId: existing.siteId,
      currencyCode: existing.currencyCode,
      depositedMinor: existing.depositedMinor +
          (tx.type == TransactionType.deposit ? tx.amountMinor : 0),
      withdrawnMinor: existing.withdrawnMinor +
          (tx.type == TransactionType.withdrawal ? tx.amountMinor : 0),
      transactionCount: existing.transactionCount + 1,
    );
  }

  var depositedBase = 0.0;
  var withdrawnBase = 0.0;
  for (final tx in transactions) {
    final currency = currencyBySite[tx.siteId] ?? baseCurrency;
    final base = convertMinorToBase(tx.amountMinor, currency, rateToBase);
    if (tx.type == TransactionType.deposit) {
      depositedBase += base;
    } else {
      withdrawnBase += base;
    }
  }

  return PortfolioData(
    baseCurrency: baseCurrency,
    siteSummaries: summaries,
    depositedBase: depositedBase,
    withdrawnBase: withdrawnBase,
    transactionCount: transactions.length,
  );
}

/// A single point on the cumulative-profit line chart.
class TimePoint {
  const TimePoint(this.date, this.cumulativeBase);
  final DateTime date;
  final double cumulativeBase;
}

/// Builds a running net-result series (in base currency), oldest → newest,
/// optionally filtered to transactions on or after [from].
List<TimePoint> buildCumulativeSeries({
  required List<Site> sites,
  required List<Transaction> transactions,
  required Map<String, double> rateToBase,
  required String baseCurrency,
  DateTime? from,
}) {
  final currencyBySite = {for (final s in sites) s.id: s.currencyCode};
  final filtered = [
    for (final tx in transactions)
      if (from == null || !tx.date.isBefore(from)) tx,
  ]..sort((a, b) => a.date.compareTo(b.date));

  final points = <TimePoint>[];
  var running = 0.0;
  for (final tx in filtered) {
    final currency = currencyBySite[tx.siteId] ?? baseCurrency;
    final base = convertMinorToBase(tx.amountMinor, currency, rateToBase);
    running += tx.type == TransactionType.deposit ? -base : base;
    points.add(TimePoint(tx.date, running));
  }
  return points;
}

/// Net result grouped by calendar month (base currency), for the bar chart.
class MonthlyNet {
  const MonthlyNet(this.month, this.netBase);

  /// First day of the month.
  final DateTime month;
  final double netBase;
}

List<MonthlyNet> buildMonthlyNet({
  required List<Site> sites,
  required List<Transaction> transactions,
  required Map<String, double> rateToBase,
  required String baseCurrency,
  DateTime? from,
}) {
  final currencyBySite = {for (final s in sites) s.id: s.currencyCode};
  final byMonth = <DateTime, double>{};
  for (final tx in transactions) {
    if (from != null && tx.date.isBefore(from)) continue;
    final key = DateTime(tx.date.year, tx.date.month);
    final currency = currencyBySite[tx.siteId] ?? baseCurrency;
    final base = convertMinorToBase(tx.amountMinor, currency, rateToBase);
    byMonth[key] = (byMonth[key] ?? 0) + (tx.type == TransactionType.deposit ? -base : base);
  }
  final entries = byMonth.entries.toList()
    ..sort((a, b) => a.key.compareTo(b.key));
  return [for (final e in entries) MonthlyNet(e.key, e.value)];
}
