import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';
import '../models/enums.dart';

/// Domain operations for deposits and withdrawals.
class TransactionRepository {
  TransactionRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Stream<List<Transaction>> watchAll() => _db.watchAllTransactions();

  Stream<List<Transaction>> watchForSite(String siteId) =>
      _db.watchTransactionsForSite(siteId);

  Future<String> createTransaction({
    required String siteId,
    required TransactionType type,
    required int amountMinor,
    required DateTime date,
    String? note,
  }) async {
    final id = _uuid.v4();
    await _db.upsertTransaction(
      TransactionsCompanion.insert(
        id: id,
        siteId: siteId,
        type: type,
        amountMinor: amountMinor,
        date: date,
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  Future<void> updateTransaction({
    required String id,
    required String siteId,
    required TransactionType type,
    required int amountMinor,
    required DateTime date,
    String? note,
  }) async {
    await _db.updateTransactionFields(
      TransactionsCompanion(
        id: Value(id),
        siteId: Value(siteId),
        type: Value(type),
        amountMinor: Value(amountMinor),
        date: Value(date),
        note: Value(note?.trim().isEmpty ?? true ? null : note!.trim()),
      ),
    );
  }

  Future<void> deleteTransaction(String id) => _db.deleteTransaction(id);

  Future<Transaction?> getById(String id) => _db.getTransaction(id);

  /// Re-inserts a previously deleted transaction verbatim (Undo).
  Future<void> restore(Transaction tx) =>
      _db.upsertTransaction(tx.toCompanion(true));
}
