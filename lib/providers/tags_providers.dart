import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/database.dart';
import 'core_providers.dart';

/// All tags, ordered by name.
final tagsProvider = StreamProvider<List<Tag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchTags(),
);

/// Every transaction↔tag join row. Folded into the derived maps below so the
/// whole feature reads from one stream (no N+1).
final transactionTagsProvider = StreamProvider<List<TransactionTag>>(
  (ref) => ref.watch(tagRepositoryProvider).watchTransactionTags(),
);

/// transactionId → its tag ids, in assignment order.
final txTagIdsProvider = Provider<Map<String, List<String>>>((ref) {
  final joins = ref.watch(transactionTagsProvider).valueOrNull ?? const [];
  final grouped = <String, List<TransactionTag>>{};
  for (final j in joins) {
    (grouped[j.transactionId] ??= []).add(j);
  }
  return {
    for (final e in grouped.entries)
      e.key: (e.value..sort((a, b) => a.position.compareTo(b.position)))
          .map((j) => j.tagId)
          .toList(),
  };
});

/// tagId → number of transactions carrying it. Drives the management screen and
/// the "most-used first" ordering in pickers.
final tagCountsProvider = Provider<Map<String, int>>((ref) {
  final joins = ref.watch(transactionTagsProvider).valueOrNull ?? const [];
  final counts = <String, int>{};
  for (final j in joins) {
    counts[j.tagId] = (counts[j.tagId] ?? 0) + 1;
  }
  return counts;
});

/// Tags as a lookup, by id.
final tagsByIdProvider = Provider<Map<String, Tag>>((ref) {
  final tags = ref.watch(tagsProvider).valueOrNull ?? const [];
  return {for (final t in tags) t.id: t};
});
