import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/enums.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(tables: [Sites, Transactions, ExchangeRates])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Used by tests to spin up an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        beforeOpen: (details) async {
          // Required for `onDelete: cascade` to actually fire in SQLite.
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---------------------------------------------------------------------------
  // Sites
  // ---------------------------------------------------------------------------

  Stream<List<Site>> watchSites() {
    return (select(sites)
          ..orderBy([
            (s) => OrderingTerm(expression: s.sortOrder),
            (s) => OrderingTerm(expression: s.name),
          ]))
        .watch();
  }

  Future<List<Site>> getSites() => select(sites).get();

  Stream<Site?> watchSite(String id) {
    return (select(sites)..where((s) => s.id.equals(id)))
        .watchSingleOrNull();
  }

  Future<void> upsertSite(SitesCompanion site) =>
      into(sites).insertOnConflictUpdate(site);

  /// Updates only the columns present in [site] on the row with its id. Unlike
  /// [upsertSite] (insert-or-update), this does NOT require the non-null
  /// insert-only columns like `createdAt`, so a partial edit is valid.
  Future<void> updateSiteFields(SitesCompanion site) =>
      (update(sites)..where((s) => s.id.equals(site.id.value))).write(site);

  Future<void> deleteSite(String id) =>
      (delete(sites)..where((s) => s.id.equals(id))).go();

  /// Re-inserts a deleted site together with the transactions that cascaded
  /// away with it (parent first so the foreign key holds). Used by Undo.
  Future<void> restoreSiteWithTransactions(
    Site site,
    List<Transaction> txns,
  ) =>
      transaction(() async {
        await upsertSite(site.toCompanion(true));
        for (final tx in txns) {
          await upsertTransaction(tx.toCompanion(true));
        }
      });

  // ---------------------------------------------------------------------------
  // Transactions
  // ---------------------------------------------------------------------------

  Stream<List<Transaction>> watchAllTransactions() {
    return (select(transactions)
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Stream<List<Transaction>> watchTransactionsForSite(String siteId) {
    return (select(transactions)
          ..where((t) => t.siteId.equals(siteId))
          ..orderBy([
            (t) => OrderingTerm(expression: t.date, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
          ]))
        .watch();
  }

  Future<List<Transaction>> getAllTransactions() =>
      select(transactions).get();

  Future<List<Transaction>> getTransactionsForSite(String siteId) =>
      (select(transactions)..where((t) => t.siteId.equals(siteId))).get();

  Future<Transaction?> getTransaction(String id) =>
      (select(transactions)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<void> upsertTransaction(TransactionsCompanion tx) =>
      into(transactions).insertOnConflictUpdate(tx);

  /// Updates only the present columns on the row with [tx]'s id — safe for a
  /// partial edit that omits insert-only columns like `createdAt`.
  Future<void> updateTransactionFields(TransactionsCompanion tx) =>
      (update(transactions)..where((t) => t.id.equals(tx.id.value)))
          .write(tx);

  Future<void> deleteTransaction(String id) =>
      (delete(transactions)..where((t) => t.id.equals(id))).go();

  /// Sum of deposits made across all sites since [since], grouped by currency.
  /// Used by the responsible-gambling deposit-limit check.
  Future<List<Transaction>> depositsSince(DateTime since) {
    return (select(transactions)
          ..where((t) =>
              t.type.equalsValue(TransactionType.deposit) &
              t.date.isBiggerOrEqualValue(since)))
        .get();
  }

  // ---------------------------------------------------------------------------
  // Exchange rates
  // ---------------------------------------------------------------------------

  Stream<List<ExchangeRate>> watchRates() => select(exchangeRates).watch();

  Future<List<ExchangeRate>> getRates() => select(exchangeRates).get();

  Future<void> upsertRate(ExchangeRatesCompanion rate) =>
      into(exchangeRates).insertOnConflictUpdate(rate);

  Future<void> deleteRate(String currencyCode) =>
      (delete(exchangeRates)..where((r) => r.currencyCode.equals(currencyCode)))
          .go();

  /// Inserts a 1:1 placeholder rate for [currencyCode] if none exists yet, so a
  /// newly used currency always has an editable row.
  Future<void> ensureRate(String currencyCode, DateTime now) async {
    await into(exchangeRates).insert(
      ExchangeRatesCompanion.insert(
        currencyCode: currencyCode,
        rateToBase: 1.0,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  // ---------------------------------------------------------------------------
  // Bulk / maintenance
  // ---------------------------------------------------------------------------

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(sites).go();
      await delete(exchangeRates).go();
    });
  }

  /// Adds sites and transactions without touching existing data — used by the
  /// additive CSV import (which merges rows in rather than replacing the DB).
  Future<void> addImported({
    required List<SitesCompanion> newSites,
    required List<TransactionsCompanion> newTransactions,
  }) async {
    await transaction(() async {
      await batch((b) {
        b.insertAll(sites, newSites);
        b.insertAll(transactions, newTransactions);
      });
    });
  }

  /// Replaces the entire database contents in a single transaction.
  /// Used when importing a backup.
  Future<void> replaceAll({
    required List<SitesCompanion> newSites,
    required List<TransactionsCompanion> newTransactions,
    required List<ExchangeRatesCompanion> newRates,
  }) async {
    await transaction(() async {
      await delete(transactions).go();
      await delete(sites).go();
      await delete(exchangeRates).go();
      await batch((b) {
        b.insertAll(sites, newSites);
        b.insertAll(exchangeRates, newRates);
        b.insertAll(transactions, newTransactions);
      });
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'betbook.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
