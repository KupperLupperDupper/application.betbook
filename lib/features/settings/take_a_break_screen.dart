import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_tokens.dart';
import '../../core/utils/date_format.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/notifications_providers.dart';
import '../../providers/settings_providers.dart';

/// Scope-honest pause: hides totals and pauses reminders for a set duration.
/// Not self-exclusion — logging keeps working and the break ends on its own or
/// on request. See NOTIFICATIONS_HANDOFF.md §5.
class TakeABreakScreen extends ConsumerWidget {
  const TakeABreakScreen({super.key});

  Future<void> _start(BuildContext context, WidgetRef ref, Duration d) async {
    final navigator = Navigator.of(context);
    await ref.read(settingsProvider.notifier).startBreak(d);
    await syncWeeklySchedule(ref);
    if (context.mounted) navigator.pop();
  }

  Future<void> _end(WidgetRef ref) async {
    await ref.read(settingsProvider.notifier).endBreak();
    await syncWeeklySchedule(ref);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.takeABreak)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Card(
            elevation: 0,
            color: scheme.surfaceContainerLow,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.takeABreakDesc,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Active-break state ------------------------------------------------
          if (settings.breakActive && settings.breakUntil != null) ...[
            Text(
              l10n.breakUntil(formatDate(settings.breakUntil!, settings.languageCode)),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: scheme.surfaceContainerLow,
              child: ListTile(
                leading: Icon(Icons.play_arrow_rounded, color: scheme.primary),
                title: Text(l10n.endBreak),
                onTap: () => _end(ref),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Duration options --------------------------------------------------
          _BreakOption(
            label: l10n.breakOption24h,
            onTap: () => _start(context, ref, const Duration(hours: 24)),
          ),
          const SizedBox(height: 12),
          _BreakOption(
            label: l10n.breakOption1week,
            onTap: () => _start(context, ref, const Duration(days: 7)),
          ),
          const SizedBox(height: 12),
          _BreakOption(
            label: l10n.breakOption1month,
            onTap: () => _start(context, ref, const Duration(days: 30)),
          ),
        ],
      ),
    );
  }
}

/// A rounded, tappable duration tile. Uses `primaryContainer` because tapping
/// it starts that break.
class _BreakOption extends StatelessWidget {
  const _BreakOption({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.card),
    );
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: scheme.primaryContainer,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        shape: shape,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: scheme.onPrimaryContainer,
          ),
        ),
        trailing: Icon(Icons.chevron_right_rounded, color: scheme.onPrimaryContainer),
        onTap: onTap,
      ),
    );
  }
}
