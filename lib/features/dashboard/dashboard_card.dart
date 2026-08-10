import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/stats/summaries.dart';
import '../../core/theme/deck_motion.dart';
import '../../core/theme/money_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/database/database.dart';
import '../../data/models/enums.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/break_providers.dart';
import '../../providers/data_providers.dart';
import '../../providers/rates_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/count_up_amount.dart';
import '../../widgets/currency_chip.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/mini_card_avatar.dart';
import '../../widgets/shuffle_refresh.dart';
import '../../widgets/skeleton.dart';
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
      loading: () => const SkeletonSwitcher(
        loading: true,
        skeleton: _DashboardSkeleton(),
        child: SizedBox.shrink(),
      ),
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
        final loading = portfolio == null;
        return SkeletonSwitcher(
          loading: loading,
          skeleton: const _DashboardSkeleton(),
          child: loading
              ? const SizedBox.shrink()
              : _DashboardBody(
                  sites: sites,
                  portfolio: portfolio,
                  localeName: locale,
                ),
        );
      },
    );
  }
}

/// Skeleton for the Dashboard deck card (MOTION_HANDOFF §4.3).
class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth - 32; // 16 padding each side
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonBlock(width: cw * 0.40, height: 12),
            const SizedBox(height: 12),
            SkeletonBlock(width: cw * 0.62, height: 44),
            const SizedBox(height: 8),
            SkeletonBlock(width: cw * 0.48, height: 16),
            const SizedBox(height: 24),
            const Row(
              children: [
                Expanded(child: SkeletonBlock(height: 88, radius: 16)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBlock(height: 88, radius: 16)),
              ],
            ),
            const SizedBox(height: 24),
            SkeletonBlock(width: cw * 0.30, height: 12),
            const SizedBox(height: 12),
            for (var i = 0; i < 3; i++) _SkeletonTxRow(contentWidth: cw),
          ],
        );
      },
    );
  }
}

class _SkeletonTxRow extends StatelessWidget {
  const _SkeletonTxRow({required this.contentWidth});

  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64,
      child: Row(
        children: [
          const SkeletonBlock(width: 36, height: 36, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBlock(width: contentWidth * 0.52, height: 16),
                const SizedBox(height: 6),
                SkeletonBlock(width: contentWidth * 0.34, height: 12),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SkeletonBlock(width: contentWidth * 0.22, height: 16),
        ],
      ),
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
    final motion = Motion.of(context);
    final base = portfolio.baseCurrency;
    final net = portfolio.netBase;

    // Hide-totals during a break (§5): running-score figures rest as an em dash
    // until the user reveals them for the session.
    final breakActive = ref.watch(settingsProvider.select((s) => s.breakActive));
    final showTotals = ref.watch(showTotalsProvider);
    final hideTotals = breakActive && !showTotals;

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

    return ShuffleRefresh(
      onRefresh: () async {
        await ref.read(ratesUpdaterProvider).refreshNow();
      },
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
        // Break state line + reveal (§5): calm one-liner while a break is on.
        if (breakActive) ...[
          _BreakStateLine(
            localeName: localeName,
            showTotalsHidden: hideTotals,
          ),
          const SizedBox(height: 12),
        ],
        // Limit state banner (§4.2) — a persistent state above the hero.
        _LimitBanner(localeName: localeName),
        Text(
          '${l10n.dashboardAllTime} · $base',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        // Hero P/L — rests as an em dash while totals are hidden.
        if (hideTotals)
          Text(
            '—',
            style: TextStyle(
              fontSize: 46,
              height: 1.05,
              fontWeight: FontWeight.w800,
              letterSpacing: -1,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else ...[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: CountUpAmount(
              value: portfolio.netBase,
              format: (v) => formatMajorSmart(v, base,
                  localeName: localeName, withSign: true),
              style: const TextStyle(
                fontSize: 46,
                height: 1.05,
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
              ),
              iconSize: 30,
              delay: motion.countUpDelay(0),
              duration: motion.countUpFor(0),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            overallLine,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: l10n.dashboardTotalDeposited,
                value: portfolio.depositedBase,
                format: (v) =>
                    formatMajorSmart(v, base, localeName: localeName),
                countUpIndex: 1,
                hidden: hideTotals,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: l10n.dashboardTotalWithdrawn,
                value: portfolio.withdrawnBase,
                format: (v) =>
                    formatMajorSmart(v, base, localeName: localeName),
                countUpIndex: 2,
                hidden: hideTotals,
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
        // The wave continues into the site rows: hero (0), deposited (1),
        // withdrawn (2), then these figures at 3, 4, … (cap 6 stops the rest).
        for (final (i, site) in visible.indexed)
          if (hideTotals)
            HiddenNetSiteTile(
              site: site,
              summary: summaries[site.id]!,
              onTap: () => context.push(Routes.siteDetail(site.id)),
            )
          else
            SiteTile(
              site: site,
              summary: summaries[site.id]!,
              localeName: localeName,
              countUpIndex: i + 3,
              onTap: () => context.push(Routes.siteDetail(site.id)),
            ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.format,
    required this.countUpIndex,
    this.hidden = false,
  });
  final String label;

  /// Raw total in base major units; counts up but stays `onSurface` (it is a
  /// cash movement, not an outcome — no profit/loss colour, no sign).
  final double value;
  final String Function(double) format;
  final int countUpIndex;

  /// While a break hides totals (§5) the figure rests as an em dash.
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = Motion.of(context);
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
          if (hidden)
            Text(
              '—',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          else
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: CountUpAmount(
                value: value,
                format: format,
                secondary: true,
                showIcon: false,
                color: theme.colorScheme.onSurface,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
                delay: motion.countUpDelay(countUpIndex),
                duration: countUpIndex < Motion.countUpMaxFigures
                    ? motion.countUpFor(countUpIndex)
                    : Duration.zero,
              ),
            ),
        ],
      ),
    );
  }
}

/// Calm one-line break state (§5): "Break until 17 Aug" with an End action, and
/// — when totals are resting — a single "Show totals" reveal for the session.
class _BreakStateLine extends ConsumerWidget {
  const _BreakStateLine({
    required this.localeName,
    required this.showTotalsHidden,
  });

  final String localeName;
  final bool showTotalsHidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final until = ref.watch(settingsProvider.select((s) => s.breakUntil));
    if (until == null) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: Text(
            l10n.breakUntil(formatDate(until, localeName)),
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        if (showTotalsHidden)
          TextButton(
            onPressed: () =>
                ref.read(showTotalsProvider.notifier).state = true,
            child: Text(l10n.showTotals),
          ),
        TextButton(
          onPressed: () async {
            await ref.read(settingsProvider.notifier).endBreak();
            // Drop the session reveal so the next break starts hidden again.
            ref.read(showTotalsProvider.notifier).state = false;
          },
          child: Text(l10n.endBreak),
        ),
      ],
    );
  }
}

/// Persistent limit-state banner (§4.2). Renders only while a threshold is
/// crossed; it is a *state*, not a message, so it carries no dismiss control and
/// vanishes on its own when the condition clears.
class _LimitBanner extends ConsumerWidget {
  const _LimitBanner({required this.localeName});

  final String localeName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rg = ref.watch(rgStatusProvider);
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final money = context.money;
    final base = ref.watch(settingsProvider.select((s) => s.baseCurrency));
    final dark = theme.brightness == Brightness.dark;

    final reached = rg.depositLimitExceeded;
    final approaching = !reached &&
        rg.depositLimitBase > 0 &&
        rg.periodDepositBase >= 0.8 * rg.depositLimitBase;
    // A deposit variant always outranks the net-loss variant when both are true.
    final netLoss = rg.netLossExceeded && !reached && !approaching;

    if (!reached && !approaching && !netLoss) return const SizedBox.shrink();

    final periodWord = switch (rg.period) {
      LimitPeriod.daily => l10n.limitPeriodDay,
      LimitPeriod.weekly => l10n.limitPeriodWeek,
      LimitPeriod.monthly => l10n.limitPeriodMonth,
    };
    late final Color container;
    late final Color ink;
    late final IconData icon;
    late final String label;
    late final String figureLine;
    Widget? track;
    final Color barBg =
        dark ? const Color(0xFF44474F) : const Color(0xFFC4C6D0);

    if (netLoss) {
      container = money.lossContainer;
      ink = money.onLossContainer;
      icon = Icons.trending_down;
      label = l10n.netLossLabel;
      figureLine = l10n.limitFigureLine(
        formatMajor(rg.netLossBase, base, localeName: localeName),
        formatMajor(rg.netLossLimitBase, base, localeName: localeName),
        periodWord,
      );
    } else {
      final pct = rg.depositLimitBase > 0
          ? ((rg.periodDepositBase / rg.depositLimitBase) * 100).floor()
          : 0;
      figureLine = l10n.limitFigureLine(
        formatMajor(rg.periodDepositBase, base, localeName: localeName),
        formatMajor(rg.depositLimitBase, base, localeName: localeName),
        periodWord,
      );
      if (reached) {
        container = money.lossContainer;
        ink = money.onLossContainer;
        icon = Icons.flag_outlined;
        label = l10n.limitReachedLabel;
        // Full track, loss-family fill (#B3401A / #FFB59A == money.loss).
        track = _ProgressTrack(value: 1, background: barBg, fill: money.loss);
      } else {
        // Approaching — neutral container (#E3E2E6 / #34353A) with its own ink.
        container = money.neutralContainer;
        ink = dark ? const Color(0xFFE3E2E6) : const Color(0xFF1A1B20);
        icon = Icons.info_outline;
        label = l10n.limitUsedPct(pct);
        track = _ProgressTrack(
          value: (pct / 100).clamp(0.0, 1.0),
          background: barBg,
          fill: dark ? const Color(0xFFDFC169) : const Color(0xFF8A6D1F),
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: container,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: ink),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(color: ink, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    figureLine,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: ink,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  if (track != null) ...[
                    const SizedBox(height: 8),
                    track,
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: () => context.push(Routes.responsibleGambling),
              style: TextButton.styleFrom(foregroundColor: ink),
              child: Text(l10n.adjust),
            ),
          ],
        ),
      ),
    );
  }
}

/// A 6 dp rounded progress track. Fills once on first paint (220 ms
/// `easeOutCubic`); drawn at its final width instantly under reduced motion.
class _ProgressTrack extends StatelessWidget {
  const _ProgressTrack({
    required this.value,
    required this.background,
    required this.fill,
  });

  final double value;
  final Color background;
  final Color fill;

  @override
  Widget build(BuildContext context) {
    final motion = Motion.of(context);
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: SizedBox(
        height: 6,
        width: double.infinity,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
          duration:
              motion.reduced ? Duration.zero : const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Stack(
            children: [
              Positioned.fill(child: ColoredBox(color: background)),
              FractionallySizedBox(
                widthFactor: v,
                alignment: Alignment.centerLeft,
                child: ColoredBox(color: fill),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A site row whose net rests as an em dash while a break hides totals (§5).
/// Mirrors [SiteTile] but omits the count-up figure; the ledger stays readable
/// elsewhere — only the running score is hidden.
class HiddenNetSiteTile extends StatelessWidget {
  const HiddenNetSiteTile({
    super.key,
    required this.site,
    required this.summary,
    this.onTap,
  });

  final Site site;
  final SiteSummary summary;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      onTap: onTap,
      leading: MiniCardAvatar(
        siteId: site.id,
        name: site.name,
        colorValue: site.colorValue,
      ),
      title: Text(
        site.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        context.l10n.siteTransactionCount(summary.transactionCount),
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CurrencyChip(code: site.currencyCode),
          const SizedBox(width: 10),
          Text(
            '—',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurfaceVariant,
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
