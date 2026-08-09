import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/utils/date_format.dart';
import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/core_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/net_text.dart';

class SiteDetailScreen extends ConsumerWidget {
  const SiteDetailScreen({super.key, required this.siteId});

  final String siteId;

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
        final deposited = txs
            .where((t) => t.type == TransactionType.deposit)
            .fold<int>(0, (s, t) => s + t.amountMinor);
        final withdrawn = txs
            .where((t) => t.type == TransactionType.withdrawal)
            .fold<int>(0, (s, t) => s + t.amountMinor);
        final net = withdrawn - deposited;

        return Scaffold(
          appBar: AppBar(
            title: Text(site.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.push(Routes.editSite(site.id)),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () =>
                context.push('${Routes.newTransaction}?siteId=${site.id}'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l10n.txAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              _SiteHeader(
                site: site,
                netMinor: net,
                depositedMinor: deposited,
                withdrawnMinor: withdrawn,
                localeName: locale,
              ),
              const SizedBox(height: 16),
              if (txs.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 48),
                  child: Center(
                    child: Text(
                      l10n.siteEmptyTransactions,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else
                for (final tx in txs)
                  _TransactionTile(
                    tx: tx,
                    currencyCode: site.currencyCode,
                    localeName: locale,
                    onTap: () => context.push(Routes.editTransaction(tx.id)),
                    onDelete: () =>
                        ref.read(transactionRepositoryProvider).deleteTransaction(tx.id),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _SiteHeader extends StatelessWidget {
  const _SiteHeader({
    required this.site,
    required this.netMinor,
    required this.depositedMinor,
    required this.withdrawnMinor,
    required this.localeName,
  });

  final Site site;
  final int netMinor;
  final int depositedMinor;
  final int withdrawnMinor;
  final String localeName;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(site.colorValue).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.siteNet,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          NetText(
            value: netMinor,
            text: formatMinor(netMinor, site.currencyCode,
                localeName: localeName, withSign: true),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            iconSize: 26,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  label: l10n.dashboardTotalDeposited,
                  value: formatMinor(depositedMinor, site.currencyCode,
                      localeName: localeName),
                ),
              ),
              Expanded(
                child: _MiniStat(
                  label: l10n.dashboardTotalWithdrawn,
                  value: formatMinor(withdrawnMinor, site.currencyCode,
                      localeName: localeName),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 2),
        Text(value,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.tx,
    required this.currencyCode,
    required this.localeName,
    required this.onTap,
    required this.onDelete,
  });

  final Transaction tx;
  final String currencyCode;
  final String localeName;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final isDeposit = tx.type == TransactionType.deposit;
    final signed = isDeposit ? -tx.amountMinor : tx.amountMinor;

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
        child: Icon(Icons.delete_rounded,
            color: theme.colorScheme.onErrorContainer),
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
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
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
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        leading: CircleAvatar(
          backgroundColor: (isDeposit
                  ? theme.colorScheme.errorContainer
                  : theme.colorScheme.primaryContainer)
              .withValues(alpha: 0.6),
          child: Icon(
            isDeposit ? Icons.south_west_rounded : Icons.north_east_rounded,
            size: 20,
          ),
        ),
        title: Text(isDeposit ? l10n.txTypeDeposit : l10n.txTypeWithdrawal),
        subtitle: Text(
          [
            formatDate(tx.date, localeName),
            if (tx.note != null && tx.note!.isNotEmpty) tx.note!,
          ].join(' · '),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: NetText(
          value: signed,
          showIcon: false,
          text: formatMinor(signed, currencyCode,
              localeName: localeName, withSign: true),
          style: theme.textTheme.titleSmall,
        ),
      ),
    );
  }
}
