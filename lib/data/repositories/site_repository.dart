import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Domain operations for gambling sites.
class SiteRepository {
  SiteRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Site>> watchSites() => _db.watchSites();

  Stream<Site?> watchSite(String id) => _db.watchSite(id);

  Future<String> createSite({
    required String name,
    required String currencyCode,
    required int colorValue,
    int? iconCodePoint,
    int sortOrder = 0,
    String? defaultTagId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    // Make sure the site's currency always has an editable rate row.
    await _db.ensureRate(currencyCode, now);
    await _db.upsertSite(
      SitesCompanion.insert(
        id: id,
        name: name.trim(),
        currencyCode: currencyCode,
        colorValue: colorValue,
        iconCodePoint: Value(iconCodePoint),
        sortOrder: Value(sortOrder),
        createdAt: now,
        defaultTagId: Value(defaultTagId),
      ),
    );
    return id;
  }

  /// [defaultTagId] is only written when the caller passes it (a present
  /// [Value]); pass `Value(null)` to clear it, or leave it absent to keep the
  /// existing default untouched.
  Future<void> updateSite({
    required String id,
    required String name,
    required String currencyCode,
    required int colorValue,
    int? iconCodePoint,
    Value<String?> defaultTagId = const Value.absent(),
  }) async {
    await _db.ensureRate(currencyCode, DateTime.now());
    await _db.upsertSite(
      SitesCompanion(
        id: Value(id),
        name: Value(name.trim()),
        currencyCode: Value(currencyCode),
        colorValue: Value(colorValue),
        iconCodePoint: Value(iconCodePoint),
        defaultTagId: defaultTagId,
      ),
    );
  }

  Future<void> deleteSite(String id) => _db.deleteSite(id);

  /// Transactions belonging to [siteId] — captured before a delete so Undo can
  /// restore them (deleting a site cascades its transactions away).
  Future<List<Transaction>> transactionsForSite(String siteId) =>
      _db.getTransactionsForSite(siteId);

  /// Re-inserts a deleted site and its captured transactions (Undo).
  Future<void> restore(Site site, List<Transaction> txns) =>
      _db.restoreSiteWithTransactions(site, txns);
}
