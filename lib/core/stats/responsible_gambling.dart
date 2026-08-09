import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../money/money_format.dart';
import 'summaries.dart';

/// Computed responsible-gambling status against the user's configured limits.
class RgStatus {
  const RgStatus({
    required this.depositLimitExceeded,
    required this.periodDepositBase,
    required this.depositLimitBase,
    required this.period,
    required this.netLossExceeded,
    required this.netLossBase,
    required this.netLossLimitBase,
  });

  final bool depositLimitExceeded;
  final double periodDepositBase;
  final double depositLimitBase;
  final LimitPeriod period;

  final bool netLossExceeded;

  /// Loss magnitude (positive) in base currency; 0 when in profit.
  final double netLossBase;
  final double netLossLimitBase;

  bool get anyExceeded => depositLimitExceeded || netLossExceeded;

  static const none = RgStatus(
    depositLimitExceeded: false,
    periodDepositBase: 0,
    depositLimitBase: 0,
    period: LimitPeriod.monthly,
    netLossExceeded: false,
    netLossBase: 0,
    netLossLimitBase: 0,
  );
}

/// Inclusive start of the current [period] relative to [now].
DateTime periodStart(LimitPeriod period, DateTime now) {
  switch (period) {
    case LimitPeriod.daily:
      return DateTime(now.year, now.month, now.day);
    case LimitPeriod.weekly:
      final midnight = DateTime(now.year, now.month, now.day);
      return midnight.subtract(Duration(days: now.weekday - 1));
    case LimitPeriod.monthly:
      return DateTime(now.year, now.month);
  }
}

RgStatus evaluateResponsibleGambling({
  required List<Site> sites,
  required List<Transaction> transactions,
  required Map<String, double> rateToBase,
  required String baseCurrency,
  required DateTime now,
  required bool depositLimitEnabled,
  required int depositLimitMinor,
  required LimitPeriod depositLimitPeriod,
  required bool netLossAlertEnabled,
  required int netLossAlertMinor,
}) {
  final currencyBySite = {for (final s in sites) s.id: s.currencyCode};

  // Deposits within the current period, in base currency.
  var periodDeposits = 0.0;
  if (depositLimitEnabled) {
    final start = periodStart(depositLimitPeriod, now);
    for (final tx in transactions) {
      if (tx.type != TransactionType.deposit) continue;
      if (tx.date.isBefore(start)) continue;
      final currency = currencyBySite[tx.siteId] ?? baseCurrency;
      periodDeposits += convertMinorToBase(tx.amountMinor, currency, rateToBase);
    }
  }
  final depositLimitBase = minorToMajor(depositLimitMinor);
  final depositExceeded = depositLimitEnabled &&
      depositLimitBase > 0 &&
      periodDeposits > depositLimitBase;

  // Overall net loss magnitude, in base currency.
  var net = 0.0;
  if (netLossAlertEnabled) {
    for (final tx in transactions) {
      final currency = currencyBySite[tx.siteId] ?? baseCurrency;
      final base = convertMinorToBase(tx.amountMinor, currency, rateToBase);
      net += tx.type == TransactionType.deposit ? -base : base;
    }
  }
  final lossMagnitude = net < 0 ? -net : 0.0;
  final netLossLimitBase = minorToMajor(netLossAlertMinor);
  final netLossExceeded = netLossAlertEnabled &&
      netLossLimitBase > 0 &&
      lossMagnitude >= netLossLimitBase;

  return RgStatus(
    depositLimitExceeded: depositExceeded,
    periodDepositBase: periodDeposits,
    depositLimitBase: depositLimitBase,
    period: depositLimitPeriod,
    netLossExceeded: netLossExceeded,
    netLossBase: lossMagnitude,
    netLossLimitBase: netLossLimitBase,
  );
}
