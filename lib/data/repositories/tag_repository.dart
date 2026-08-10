import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../database/database.dart';

/// Domain operations for tags and their transaction assignments.
/// See TAGS_HANDOFF.md.
class TagRepository {
  TagRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  /// The case-insensitive uniqueness key: trimmed + lowercased. Danish æøå
  /// fold correctly under [String.toLowerCase].
  static String fold(String name) => name.trim().toLowerCase();

  Stream<List<Tag>> watchTags() => _db.watchTags();

  Stream<List<TransactionTag>> watchTransactionTags() =>
      _db.watchTransactionTags();

  Future<List<String>> tagIdsForTransaction(String txId) =>
      _db.tagIdsForTransaction(txId);

  Future<void> setTransactionTags(String txId, List<String> tagIds) =>
      _db.setTransactionTags(txId, tagIds);

  /// Creates a tag if its folded name is new, else returns the existing tag's
  /// id (never a case-only duplicate). Returns the resolved id.
  Future<String> createOrGet(String name) async {
    final folded = fold(name);
    final existing = await _db.getTagByFolded(folded);
    if (existing != null) return existing.id;
    final id = _uuid.v4();
    await _db.upsertTag(
      TagsCompanion.insert(
        id: id,
        name: name.trim(),
        nameFolded: folded,
        createdAt: DateTime.now(),
      ),
    );
    return id;
  }

  /// Renames [tag]; returns false (and makes no change) if the new folded name
  /// collides with a *different* tag.
  Future<bool> rename(Tag tag, String newName) async {
    final folded = fold(newName);
    final clash = await _db.getTagByFolded(folded);
    if (clash != null && clash.id != tag.id) return false;
    await _db.upsertTag(
      tag.toCompanion(true).copyWith(
            name: Value(newName.trim()),
            nameFolded: Value(folded),
          ),
    );
    return true;
  }

  Future<void> setDot(Tag tag, String? dot) =>
      _db.upsertTag(tag.toCompanion(true).copyWith(dot: Value(dot)));

  /// Deletes a tag, returning the assignment rows it carried so Undo can
  /// restore both the tag and every assignment.
  Future<List<TransactionTag>> deleteCapturing(String tagId) async {
    final joins = await _db.getTransactionTagsForTag(tagId);
    await _db.deleteTagById(tagId);
    return joins;
  }

  Future<void> restore(Tag tag, List<TransactionTag> joins) =>
      _db.restoreTagWithAssignments(tag, joins);

  Future<void> merge(String sourceId, String targetId) =>
      _db.mergeTags(sourceId, targetId);
}
