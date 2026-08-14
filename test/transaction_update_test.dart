import 'package:betbook/data/database/database.dart';
import 'package:betbook/data/models/enums.dart';
import 'package:betbook/data/repositories/site_repository.dart';
import 'package:betbook/data/repositories/transaction_repository.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('updateTransaction persists the change', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sites = SiteRepository(db);
    final txs = TransactionRepository(db);

    final siteId = await sites.createSite(
      name: 'Bet365',
      currencyCode: 'DKK',
      colorValue: 0xFF3E5CF0,
    );
    final id = await txs.createTransaction(
      siteId: siteId,
      type: TransactionType.deposit,
      amountMinor: 50000,
      date: DateTime(2026, 8, 1),
    );

    await txs.updateTransaction(
      id: id,
      siteId: siteId,
      type: TransactionType.withdrawal,
      amountMinor: 12345,
      date: DateTime(2026, 8, 2),
      note: 'edited',
    );

    final row = await db.getTransaction(id);
    expect(row, isNotNull);
    expect(row!.type, TransactionType.withdrawal);
    expect(row.amountMinor, 12345);
    expect(row.note, 'edited');

    await db.close();
  });

  test('updateSite persists the change', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final sites = SiteRepository(db);

    final id = await sites.createSite(
      name: 'Bet365',
      currencyCode: 'DKK',
      colorValue: 0xFF3E5CF0,
    );
    await sites.updateSite(
      id: id,
      name: 'Unibet',
      currencyCode: 'EUR',
      colorValue: 0xFF1B7F52,
    );

    final row = await (db.select(db.sites)..where((s) => s.id.equals(id)))
        .getSingleOrNull();
    expect(row, isNotNull);
    expect(row!.name, 'Unibet');
    expect(row.currencyCode, 'EUR');
    // createdAt survives a partial update (the bug was it being required).
    expect(row.createdAt, isNotNull);

    await db.close();
  });
}
