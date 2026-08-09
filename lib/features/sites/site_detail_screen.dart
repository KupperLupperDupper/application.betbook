import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/theme/money_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';

class SiteDetailScreen extends ConsumerWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

  Future<void> _confirmDeleteSite(
    BuildContext context,
    WidgetRef ref,
    Site site,
  ) async {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.siteDelete),
        content: Text(l10n.siteDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.actionCancel),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.actionDelete),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(siteRepositoryProvider).deleteSite(site.id);
    if (context.mounted) context.go(Routes.home);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final siteAsync = ref.watch(siteByIdProvider(siteId));
    final txAsync = ref.watch(siteTransactionsProvider(siteId));
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));

    return siteAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text(l10n.commonError))),
      data: (site) {
        if (site == null) {
          // Site was deleted — leave the screen.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) context.go(Routes.home);
          });
          return const Scaffold();
        }

        final txs = txAsync.valueOrNull ?? const <Transaction>[];
        final depositedMinor = txs
            .where((t) => t.type == TransactionType.deposit)
            .fold<int>(0, (s, t) => s + t.amountMinor);
        final withdrawnMinor = txs
            .where((t) => t.type == TransactionType.withdrawal)
            .fold<int>(0, (s, t) => s + t.amountMinor);
        final net = withdrawnMinor - depositedMinor;

        // Running net (withdrawals − deposits), accumulated oldest → newest.
        final runningNet = <String, int>{};
        var cumulative = 0;
        for (final tx in txs.reversed) {
          cumulative += tx.type == TransactionType.withdrawal
              ? tx.amountMinor
              : -tx.amountMinor;
          runningNet[tx.id] = cumulative;
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(site.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(Routes.editSite(site.id)),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded),
                color: Theme.of(context).colorScheme.error,
                onPressed: () => _confirmDeleteSite(context, ref, site),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.push('${Routes.newTransaction}?siteId=${site.id}'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.txAdd),
          ),
          body: txs.isEmpty
              ? EmptyState(
                  title: l10n.siteDetailEmptyTitle,
                  message: l10n.siteDetailEmptyBody,
                  actionLabel: l10n.txAdd,
                  onAction: () => context
                      .push('${Routes.newTransaction}?siteId=${site.id}'),
                )
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    _HeroCard(
                      site: site,
                      netMinor: net,
                      depositedMinor: depositedMinor,
                      withdrawnMinor: withdrawnMinor,
                      locale: locale,
                    ),
                    const SizedBox(height: 16),
                    ..._buildTransactionSlivers(
                      context: context,
                      ref: ref,
                      txs: txs,
                      runningNet: runningNet,
                      locale: locale,
                    ),
                  ],
                ),
        );
      },
    );
  }

  /// Groups [txs] (already newest-first) by month and returns header +
  /// row widgets in display order.
  List<Widget> _buildTransactionSlivers({
    required BuildContext context,
    required WidgetRef ref,
    required List<Transaction> txs,
    required Map<String, int> runningNet,
    required String locale,
  }) {
    final widgets = <Widget>[];
    String? currentKey;
    for (final tx in txs) {
      final key = '${tx.date.year}-${tx.date.month}';
      if (key != currentKey) {
        currentKey = key;
        widgets.add(_MonthHeader(date: tx.date, locale: locale));
      }
      widgets.add(
        _TransactionRow(
          tx: tx,
          locale: locale,
          runningNet: runningNet[tx.id] ?? 0,
          onTap: () => context.push(Routes.editTransaction(tx.id)),
          onDelete: () => ref
              .read(transactionRepositoryProvider)
              .deleteTransaction(tx.id),
        ),
      );
    }
    return widgets;
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.site,
    required this.netMinor,
    required this.depositedMinor,
    required this.withdrawnMinor,
    required this.locale,
  });

  final Site site;
  final int netMinor;
  final int depositedMinor;
  final int withdrawnMinor;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final netColor = context.money.forAmount(netMinor);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                context.money.iconForAmount(netMinor),
                color: netColor,
                size: 26,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatMinor(netMinor, site.currencyCode,
                      localeName: locale, withSign: true),
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: netColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeroStat(
                  label: l10n.dashboardTotalDeposited,
                  value: formatMinorPlain(depositedMinor, localeName: locale),
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: l10n.dashboardTotalWithdrawn,
                  value: formatMinorPlain(withdrawnMinor, localeName: locale),
                ),
              ),
              Expanded(
                child: _HeroStat(
                  label: l10n.commonCurrency,
                  value: site.currencyCode,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: theme.textTheme.labelMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleMedium
              ?.copyWith(color: theme.colorScheme.onSurface),
        ),
      ],
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({required this.date, required this.locale});

  final DateTime date;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final raw = formatMonth(date, locale);
    final label =
        raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Text(
        label,
        style: theme.textTheme.titleSmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _TransactionRow extends StatelessWidget {
  const _TransactionRow({
    required this.tx,
    required this.locale,
    required this.runningNet,
    required this.onTap,
    required this.onDelete,
  });

  final Transaction tx;
  final String locale;
  final int runningNet;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = context.money;
    final isDeposit = tx.type == TransactionType.deposit;

    final dateTime = DateFormat('d MMM · HH:mm', locale).format(tx.date);
    final subtitle = [
      dateTime,
      if (tx.note != null && tx.note!.isNotEmpty) tx.note!,
    ].join(' · ');

    final signedAmount = formatMinorPlain(
      isDeposit ? -tx.amountMinor : tx.amountMinor,
      localeName: locale,
      withSign: true,
    );

    return Dismissible(
      key: ValueKey(tx.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.delete_rounded,
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text(l10n.txDelete),
                content: Text(l10n.txDeleteConfirm),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: Text(l10n.actionCancel),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                    ),
                    onPressed: () => Navigator.pop(ctx, true),
                    child: Text(l10n.actionDelete),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete(),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: ListTile(
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: CircleAvatar(
            radius: 20,
            backgroundColor:
                isDeposit ? money.lossContainer : money.profitContainer,
            child: Icon(
              isDeposit
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 20,
              color:
                  isDeposit ? money.onLossContainer : money.onProfitContainer,
            ),
          ),
          title: Text(isDeposit ? l10n.txTypeDeposit : l10n.txTypeWithdrawal),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                signedAmount,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                l10n.txRunningNet(
                  formatMinorPlain(runningNet,
                      localeName: locale, withSign: true),
                ),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
