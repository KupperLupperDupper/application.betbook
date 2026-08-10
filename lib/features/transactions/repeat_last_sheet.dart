import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/money/amount_input.dart';
import '../../core/money/money_format.dart';
import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/mini_card_avatar.dart';
import '../../widgets/undo_snackbar.dart';

/// Confirm sheet for repeat-last. Shows exactly what will be written — never a
/// one-tap silent commit. Note is not copied: it described the source entry,
/// not this one.
Future<void> showRepeatLastSheet(
  BuildContext context, {
  required Transaction source,
  required Site site,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _RepeatLastSheet(source: source, site: site),
  );
}

class _RepeatLastSheet extends ConsumerWidget {
  const _RepeatLastSheet({required this.source, required this.site});

  final Transaction source;
  final Site site;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));
    final isDeposit = source.type == TransactionType.deposit;
    final typeLabel = isDeposit ? l10n.txTypeDeposit : l10n.txTypeWithdrawal;
    final now = DateTime.now();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l10n.repeatEntry, style: theme.textTheme.titleLarge),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.7),
                ),
              ),
              child: Row(
                children: [
                  MiniCardAvatar(
                    siteId: site.id,
                    name: site.name,
                    colorValue: site.colorValue,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(site.name,
                            style: theme.textTheme.titleMedium,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          '$typeLabel · ${l10n.quickAddDatedNow(DateFormat.Hm(locale).format(now))}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    formatMinorPlain(source.amountMinor,
                        localeName: locale),
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    // Open the full editor pre-filled with the source values.
                    final uri = Uri(
                      path: Routes.newTransaction,
                      queryParameters: {
                        'siteId': site.id,
                        'type': source.type.name,
                        'amount': AmountInput.rawFromMajor(
                            minorToMajor(source.amountMinor)),
                      },
                    );
                    context.push(uri.toString());
                  },
                  child: Text(l10n.actionEdit),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: () => _commit(context, ref, now),
                  child: Text(l10n.actionSave),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _commit(
      BuildContext context, WidgetRef ref, DateTime now) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = context.l10n;
    final repo = ref.read(transactionRepositoryProvider);
    final id = await repo.createTransaction(
      siteId: source.siteId,
      type: source.type,
      amountMinor: source.amountMinor,
      date: now,
    );
    if (context.mounted) Navigator.of(context).pop();
    showUndoSnackBar(
      messenger,
      message: l10n.quickAddSaved,
      undoLabel: l10n.actionUndo,
      onUndo: () => repo.deleteTransaction(id),
    );
  }
}
