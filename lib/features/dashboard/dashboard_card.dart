import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/stats/summaries.dart';
import '../../core/theme/money_colors.dart';
import '../../data/database/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
import '../sites/widgets/site_tile.dart';
import 'widgets/profit_sparkline.dart';

class DashboardCard extends ConsumerWidget {
  const DashboardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sitesAsync = ref.watch(sitesProvider);
    final portfolio = ref.watch(portfolioProvider);
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));

    return sitesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.commonError)),
      data: (sites) {
        if (sites.isEmpty) {
          return EmptyState(
            icon: Icons.account_balance_wallet_rounded,
            title: l10n.dashboardEmptyTitle,
            message: l10n.dashboardEmptyBody,
            actionLabel: l10n.dashboardAddSite,
            onAction: () => context.push(Routes.newSite),
          );
        }
        if (portfolio == null) {
          return const Center(child: CircularProgressIndicator());
        }
        return _DashboardBody(
          sites: sites,
          portfolio: portfolio,
          localeName: locale,
        );
      },
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({
    required this.sites,
    required this.portfolio,
    required this.localeName,
  });

  final List<Site> sites;
  final PortfolioData portfolio;
  final String localeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final base = portfolio.baseCurrency;

    final series = buildCumulativeSeries(
      sites: sites,
      transactions: ref.watch(allTransactionsProvider).valueOrNull ?? const [],
      rateToBase: ref.watch(rateMapProvider),
      baseCurrency: base,
    );

    // Top sites by absolute net, in each site's own currency.
    final summaries = portfolio.siteSummaries;
    final topSites = [...sites]
      ..sort((a, b) {
        final na = summaries[a.id]?.netMinor.abs() ?? 0;
        final nb = summaries[b.id]?.netMinor.abs() ?? 0;
        return nb.compareTo(na);
      });
    final visible = topSites.take(4).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
      children: [
        Text(
          l10n.dashboardNetResult,
          style: theme.textTheme.labelLarge
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 6),
        Text(
          formatMajor(portfolio.netBase, base, localeName: localeName, withSign: true),
          style: theme.textTheme.displaySmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.money.forAmount(portfolio.netBase),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                label: l10n.dashboardTotalDeposited,
                value: formatMajor(portfolio.depositedBase, base, localeName: localeName),
                icon: Icons.south_west_rounded,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatTile(
                label: l10n.dashboardTotalWithdrawn,
                value: formatMajor(portfolio.withdrawnBase, base, localeName: localeName),
                icon: Icons.north_east_rounded,
              ),
            ),
          ],
        ),
        if (series.length >= 2) ...[
          const SizedBox(height: 20),
          Text(
            l10n.dashboardProfitOverTime,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          ProfitSparkline(points: series, height: 72),
        ],
        const SizedBox(height: 20),
        Text(
          l10n.dashboardYourSites,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        for (final site in visible)
          SiteTile(
            site: site,
            summary: summaries[site.id]!,
            localeName: localeName,
            onTap: () => context.push(Routes.siteDetail(site.id)),
          ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
