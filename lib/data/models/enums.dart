/// The kind of money movement for a transaction.
///
/// Stored in the database as its [index] via Drift's `intEnum`, so the order of
/// these values must never change (append new values at the end only).
enum TransactionType {
  /// Money the user paid into a site.
  deposit,

  /// Money the user took out of a site.
  withdrawal,
}

extension TransactionTypeX on TransactionType {
  bool get isDeposit => this == TransactionType.deposit;
  bool get isWithdrawal => this == TransactionType.withdrawal;

  /// Sign applied to an amount when computing net result
  /// (withdrawals add to profit, deposits subtract).
  int get netSign => isWithdrawal ? 1 : -1;
}

/// Period a responsible-gambling deposit limit is measured over.
enum LimitPeriod { daily, weekly, monthly }
