import 'package:fl_chart/fl_chart.dart';
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
        if (sites.isEmpty || (portfolio != null && portfolio.isEmpty)) {
          return EmptyState(
            title: l10n.dashboardEmptyTitle,
            message: l10n.dashboardEmptyBody,
            actionLabel: l10n.txAdd,
            onAction: () => context.push(Routes.newTransaction),
            footnote: l10n.allDataOnDevice,
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
    final money = context.money;
    final base = portfolio.baseCurrency;
    final net = portfolio.netBase;

    final series = buildCumulativeSeries(
      sites: sites,
      transactions: ref.watch(allTransactionsProvider).valueOrNull ?? const [],
      rateToBase: ref.watch(rateMapProvider),
      baseCurrency: base,
    );

    final summaries = portfolio.siteSummaries;
    final topSites = [...sites]
      ..sort((a, b) {
        final na = summaries[a.id]?.netMinor.abs() ?? 0;
        final nb = summaries[b.id]?.netMinor.abs() ?? 0;
        return nb.compareTo(na);
      });
    final visible = topSites.take(4).toList();

    final overallLine = net > 0
        ? l10n.dashboardUpOverall
        : net < 0
            ? l10n.dashboardDownOverall
            : l10n.dashboardEvenOverall;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
      children: [
        Text(
          '${l10n.dashboardAllTime} · $base',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        // Hero P/L
        Row(
          children: [
            Icon(money.iconForAmount(net), color: money.forAmount(net), size: 30),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  formatMajorSmart(net, base, localeName: localeName, withSign: true),
                  style: TextStyle(
                    fontSize: 46,
                    height: 1.05,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                    color: money.forAmount(net),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          overallLine,
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.dashboardTotalDeposited,
                value: formatMajorSmart(portfolio.depositedBase, base,
                    localeName: localeName),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.dashboardTotalWithdrawn,
                value: formatMajorSmart(portfolio.withdrawnBase, base,
                    localeName: localeName),
              ),
            ),
          ],
        ),
        if (series.length >= 2) ...[
          const SizedBox(height: 14),
          _ChartCard(series: series, color: money.forAmount(net), title: l10n.dashboardProfitOverTime),
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

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.series,
    required this.color,
    required this.title,
  });
  final List<TimePoint> series;
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].cumulativeBase),
    ];
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineTouchData: const LineTouchData(enabled: false),
                minX: 0,
                maxX: (series.length - 1).toDouble(),
                extraLinesData: ExtraLinesData(horizontalLines: [
                  HorizontalLine(
                    y: 0,
                    color: theme.colorScheme.outlineVariant,
                    strokeWidth: 1,
                    dashArray: [3, 4],
                  ),
                ]),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    curveSmoothness: 0.25,
                    barWidth: 2.5,
                    color: color,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
