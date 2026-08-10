import 'package:drift/drift.dart';

import '../models/enums.dart';

/// A gambling / betting site the user tracks (e.g. Bet365, Unibet).
class Sites extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  TextColumn get name => text().withLength(min: 1, max: 100)();

  /// ISO-4217 currency code this site is denominated in, e.g. `DKK`, `EUR`.
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  /// ARGB colour used to tint the site's card/badge.
  IntColumn get colorValue => integer()();

  /// Optional Material icon code point for the site avatar.
  IntColumn get iconCodePoint => integer().nullable()();

  /// Manual ordering in lists (lower = first).
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single deposit or withdrawal on a [Sites] row.
class Transactions extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  TextColumn get siteId =>
      text().references(Sites, #id, onDelete: KeyAction.cascade)();

  /// Deposit or withdrawal. Stored as the enum index.
  IntColumn get type => intEnum<TransactionType>()();

  /// Amount in the site's currency, stored in **minor units** (2 decimals,
  /// e.g. øre/cents) so money maths stays exact — never a floating amount.
  IntColumn get amountMinor => integer()();

  /// When the money actually moved (user-editable).
  DateTimeColumn get date => dateTime()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// User-editable conversion rate for a currency into the app's base currency.
///
/// [rateToBase] is "how many base-currency units equal 1 unit of this
/// currency" — e.g. with base `DKK`, `EUR` has a rate of ~7.46.
class ExchangeRates extends Table {
  TextColumn get currencyCode => text().withLength(min: 3, max: 3)();

  RealColumn get rateToBase => real()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {currencyCode};
}
