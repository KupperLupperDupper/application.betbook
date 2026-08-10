import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/enums.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
    tables: [Sites, Transactions, ExchangeRates, Tags, TransactionTags])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  /// Used by tests to spin up an in-memory database.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_tt_tag ON transaction_tags(tag_id)');
        },
        onUpgrade: (m, from, to) async {
          // v2: tags + transaction_tags join + sites.default_tag_id.
          if (from < 2) {
            await m.createTable(tags);
            await m.createTable(transactionTags);
            await m.addColumn(sites, sites.defaultTagId);
            await customStatement(
                'CREATE INDEX IF NOT EXISTS idx_tt_tag ON transaction_tags(tag_id)');
          }
        },
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
  // Tags
  // ---------------------------------------------------------------------------

  Stream<List<Tag>> watchTags() =>
      (select(tags)..orderBy([(t) => OrderingTerm(expression: t.name)]))
          .watch();

  Future<List<Tag>> getTags() => select(tags).get();

  Future<Tag?> getTagByFolded(String folded) =>
      (select(tags)..where((t) => t.nameFolded.equals(folded)))
          .getSingleOrNull();

  Future<void> upsertTag(TagsCompanion tag) =>
      into(tags).insertOnConflictUpdate(tag);

  Future<void> deleteTagById(String id) =>
      (delete(tags)..where((t) => t.id.equals(id))).go();

  /// All join rows — provider-side we fold these into per-transaction tag sets
  /// and per-tag counts (one stream, no N+1).
  Stream<List<TransactionTag>> watchTransactionTags() =>
      select(transactionTags).watch();

  Future<List<TransactionTag>> getTransactionTagsForTag(String tagId) =>
      (select(transactionTags)..where((t) => t.tagId.equals(tagId))).get();

  Future<List<String>> tagIdsForTransaction(String txId) async {
    final rows = await (select(transactionTags)
          ..where((t) => t.transactionId.equals(txId))
          ..orderBy([(t) => OrderingTerm(expression: t.position)]))
        .get();
    return [for (final r in rows) r.tagId];
  }

  /// Replaces a transaction's tag set, preserving order via [position].
  Future<void> setTransactionTags(String txId, List<String> tagIds) async {
    await transaction(() async {
      await (delete(transactionTags)
            ..where((t) => t.transactionId.equals(txId)))
          .go();
      await batch((b) {
        for (var i = 0; i < tagIds.length; i++) {
          b.insert(
            transactionTags,
            TransactionTagsCompanion.insert(
              transactionId: txId,
              tagId: tagIds[i],
              position: Value(i),
            ),
          );
        }
      });
    });
  }

  /// Re-inserts a deleted tag and every assignment it carried (Undo).
  Future<void> restoreTagWithAssignments(
      Tag tag, List<TransactionTag> joins) async {
    await transaction(() async {
      await into(tags).insertOnConflictUpdate(tag.toCompanion(true));
      await batch((b) => b.insertAllOnConflictUpdate(
          transactionTags, [for (final j in joins) j.toCompanion(true)]));
    });
  }

  /// Moves every assignment from [sourceId] to [targetId] (deduping), moves any
  /// site defaults, then deletes the source tag.
  Future<void> mergeTags(String sourceId, String targetId) async {
    await transaction(() async {
      final sourceJoins = await (select(transactionTags)
            ..where((t) => t.tagId.equals(sourceId)))
          .get();
      for (final j in sourceJoins) {
        final exists = await (select(transactionTags)
              ..where((t) =>
                  t.transactionId.equals(j.transactionId) &
                  t.tagId.equals(targetId)))
            .getSingleOrNull();
        if (exists == null) {
          await into(transactionTags).insert(
            TransactionTagsCompanion.insert(
              transactionId: j.transactionId,
              tagId: targetId,
              position: Value(j.position),
            ),
          );
        }
      }
      await (update(sites)..where((s) => s.defaultTagId.equals(sourceId)))
          .write(SitesCompanion(defaultTagId: Value(targetId)));
      await (delete(tags)..where((t) => t.id.equals(sourceId))).go();
    });
  }

  // ---------------------------------------------------------------------------
  // Bulk / maintenance
  // ---------------------------------------------------------------------------

  Future<void> clearAll() async {
    await transaction(() async {
      await delete(transactionTags).go();
      await delete(transactions).go();
      await delete(sites).go();
      await delete(exchangeRates).go();
      await delete(tags).go();
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
