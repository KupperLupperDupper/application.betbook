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
      ),
    );
    return id;
  }

  Future<void> updateSite({
    required String id,
    required String name,
    required String currencyCode,
    required int colorValue,
    int? iconCodePoint,
  }) async {
    await _db.ensureRate(currencyCode, DateTime.now());
    await _db.upsertSite(
      SitesCompanion(
        id: Value(id),
        name: Value(name.trim()),
        currencyCode: Value(currencyCode),
        colorValue: Value(colorValue),
        iconCodePoint: Value(iconCodePoint),
      ),
    );
  }

  Future<void> deleteSite(String id) => _db.deleteSite(id);
}
