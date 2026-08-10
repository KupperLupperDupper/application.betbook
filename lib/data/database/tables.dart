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

  /// Optional tag prefilled onto new transactions for this site. Cleared to
  /// null if the tag is deleted (never rewrites existing transactions).
  TextColumn get defaultTagId =>
      text().nullable().references(Tags, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A user-defined label. Attached to transactions many-to-many via
/// [TransactionTags]; used to filter Stats. See TAGS_HANDOFF.md.
class Tags extends Table {
  /// UUID primary key.
  TextColumn get id => text()();

  /// Display name, 1–24 chars, trimmed. Casing is the first-created casing.
  TextColumn get name => text().withLength(min: 1, max: 24)();

  /// Trimmed, lowercased, NFC-folded uniqueness key (`Poker` == `poker`).
  TextColumn get nameFolded => text()();

  /// Optional identifying-dot palette enum name (`blue`…`slate`) or null.
  TextColumn get dot => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {nameFolded},
      ];
}

/// Join row assigning a [Tags] to a [Transactions]. [position] preserves the
/// user's assignment order for the row-overflow rule.
class TransactionTags extends Table {
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();

  TextColumn get tagId =>
      text().references(Tags, #id, onDelete: KeyAction.cascade)();

  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {transactionId, tagId};
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
