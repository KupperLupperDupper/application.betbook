import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/routes.dart';
import '../../core/money/money_format.dart';
import '../../core/stats/summaries.dart';
import '../../core/theme/deck_motion.dart';
import '../../core/theme/money_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/database/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../providers/tags_providers.dart';
import '../../widgets/count_up_amount.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/skeleton.dart';
import '../../widgets/suit_marks.dart';
import '../../widgets/tag_chip.dart';
import '../tags/tag_picker_sheet.dart';

/// Session-only tag filter for Stats (TAGS_HANDOFF §7.1). It resets on cold
/// start by design — a remembered filter would make a partial figure read as a
/// total — so this is a plain [StateProvider] with no persistence.
final tagFilterProvider = StateProvider<List<String>>((ref) => const []);

/// Short, symbol-less axis label (e.g. `4,8K`, `0`, `-200`) — the currency
/// symbol on every gridline made labels too wide and they overlapped.
String _axisLabel(double value, String locale) =>
    NumberFormat.compact(locale: locale).format(value);

enum _Range { d7, d30, d90, year, all }

class StatsCard extends ConsumerStatefulWidget {
  const StatsCard({super.key});

  @override
  ConsumerState<StatsCard> createState() => _StatsCardState();
}

class _StatsCardState extends ConsumerState<StatsCard> {
  _Range _range = _Range.d30;

  DateTime? _from() {
    final now = DateTime.now();
    return switch (_range) {
      _Range.d7 => now.subtract(const Duration(days: 7)),
      _Range.d30 => now.subtract(const Duration(days: 30)),
      _Range.d90 => now.subtract(const Duration(days: 90)),
      _Range.year => DateTime(now.year),
      _Range.all => null,
    };
  }

  String _rangeLabel(_Range r, BuildContext c) => switch (r) {
        _Range.d7 => c.l10n.statsRangeLast7,
        _Range.d30 => c.l10n.statsRangeLast30,
        _Range.d90 => c.l10n.statsRangeLast90,
        _Range.year => c.l10n.statsRangeYear,
        _Range.all => c.l10n.statsRangeAll,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final locale = ref.watch(settingsProvider.select((s) => s.languageCode));
    final base = ref.watch(settingsProvider.select((s) => s.baseCurrency));
    final sitesAsync = ref.watch(sitesProvider);
    final txsAsync = ref.watch(allTransactionsProvider);
    final rates = ref.watch(rateMapProvider);

    // While the deck-card list is about to appear, show the skeleton.
    if (sitesAsync.isLoading || txsAsync.isLoading) {
      return const SkeletonSwitcher(
        loading: true,
        skeleton: _StatsSkeleton(),
        child: SizedBox.shrink(),
      );
    }

    final sites = sitesAsync.valueOrNull ?? const <Site>[];
    final txs = txsAsync.valueOrNull ?? const <Transaction>[];

    if (txs.length < 2) {
      return SkeletonSwitcher(
        loading: false,
        skeleton: const _StatsSkeleton(),
        child: EmptyState(
          title: l10n.statsNoData,
          message: l10n.statsNoDataBody,
          actionLabel: l10n.txAdd,
          onAction: () => context.push(Routes.newTransaction),
        ),
      );
    }

    // ── Tags + session filter (§7) ─────────────────────────────────────────
    final allTags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];
    final tagCounts = ref.watch(tagCountsProvider);
    final tagsById = ref.watch(tagsByIdProvider);
    final txTagIds = ref.watch(txTagIdsProvider);
    final selected = ref.watch(tagFilterProvider);
    final tagsExist = allTags.isNotEmpty;
    final filterActive = selected.isNotEmpty;

    bool matches(Transaction tx) {
      final ids = txTagIds[tx.id];
      return ids != null && ids.any(selected.contains);
    }

    void setFilter(List<String> v) =>
        ref.read(tagFilterProvider.notifier).state = v;
    void toggle(String id) {
      final cur = [...selected];
      if (cur.contains(id)) {
        cur.remove(id);
      } else if (cur.length < 3) {
        cur.add(id);
      }
      setFilter(cur);
    }

    final from = _from();
    // When a filter is active, every element re-reads from the transactions
    // whose tag set intersects the selection (OR); untagged rows are excluded.
    // The pure functions still apply the active range via [from].
    final List<Transaction> seriesTxs =
        filterActive ? txs.where(matches).toList() : txs;

    final series = buildCumulativeSeries(
      sites: sites,
      transactions: seriesTxs,
      rateToBase: rates,
      baseCurrency: base,
      from: from,
    );
    final monthsUnfiltered = buildMonthlyNet(
      sites: sites,
      transactions: txs,
      rateToBase: rates,
      baseCurrency: base,
      from: from,
    );
    // Keep the full month axis under a filter: months with no matching entry
    // render as an empty (zero) track so the shape of the year stays readable.
    final List<MonthlyNet> monthly;
    if (filterActive) {
      final filteredByMonth = {
        for (final m in buildMonthlyNet(
          sites: sites,
          transactions: seriesTxs,
          rateToBase: rates,
          baseCurrency: base,
          from: from,
        ))
          m.month: m.netBase,
      };
      monthly = [
        for (final m in monthsUnfiltered)
          MonthlyNet(m.month, filteredByMonth[m.month] ?? 0.0),
      ];
    } else {
      monthly = monthsUnfiltered;
    }
    final rangeNet = series.isEmpty ? 0.0 : series.last.cumulativeBase;

    // Per-site figures. Unfiltered keeps the app-wide (all-time) portfolio; a
    // filter recomputes locally from range + tag scoped transactions and keeps
    // only sites with at least one match.
    final Map<String, SiteSummary> summaries;
    if (filterActive) {
      final scoped = [
        for (final tx in seriesTxs)
          if (from == null || !tx.date.isBefore(from)) tx,
      ];
      final fp = computePortfolio(
        sites: sites,
        transactions: scoped,
        rateToBase: rates,
        baseCurrency: base,
      );
      summaries = {
        for (final e in fp.siteSummaries.entries)
          if (e.value.transactionCount > 0) e.key: e.value,
      };
    } else {
      summaries = ref.watch(portfolioProvider)?.siteSummaries ??
          const <String, SiteSummary>{};
    }

    // Filter active but nothing matched in range → single empty state (§7.3).
    final emptyUnderFilter = filterActive && series.isEmpty;

    final selectedNames = [
      for (final id in selected)
        if (tagsById[id] != null) tagsById[id]!.name,
    ];
    final headerNames = selectedNames.length <= 2
        ? selectedNames.join(', ')
        : '${selectedNames.take(2).join(', ')} +${selectedNames.length - 2}';

    final motion = Motion.of(context);

    Widget body;
    if (emptyUnderFilter) {
      body = Padding(
        key: const ValueKey('stats-empty'),
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const SuitGlyphMark(size: 48),
            const SizedBox(height: 16),
            Text(
              l10n.noEntriesForTag,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.noEntriesForTagBody,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => setFilter(const []),
              child: Text(l10n.clearFilter),
            ),
          ],
        ),
      );
    } else {
      body = Column(
        key: ValueKey('stats-body:$filterActive:${selected.join(",")}'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.statsNetResult,
              style: theme.textTheme.labelLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          CountUpAmount(
            value: rangeNet,
            format: (v) =>
                formatMajor(v, base, localeName: locale, withSign: true),
            style: theme.textTheme.headlineMedium
                ?.copyWith(fontWeight: FontWeight.w800),
            iconSize: 24,
          ),
          const SizedBox(height: 24),
          if (series.length >= 2) ...[
            _SectionCard(
              title: l10n.dashboardProfitOverTime,
              child: _LineChartBox(series: series, base: base, locale: locale),
            ),
            const SizedBox(height: 14),
          ],
          _SectionCard(
            title: l10n.statsBySite,
            child: _SiteBreakdown(
              sites: sites,
              summaries: summaries,
              rates: rates,
              base: base,
              locale: locale,
            ),
          ),
          const SizedBox(height: 14),
          _BestWorstCards(
            sites: sites,
            summaries: summaries,
            rates: rates,
            base: base,
            locale: locale,
            filtered: filterActive,
          ),
          if (monthly.isNotEmpty) ...[
            const SizedBox(height: 14),
            _SectionCard(
              title: l10n.statsByMonth,
              child: _MonthlyBarChart(
                data: monthly,
                base: base,
                locale: locale,
                showTracks: filterActive,
              ),
            ),
          ],
        ],
      );
    }

    return SkeletonSwitcher(
      loading: false,
      skeleton: const _StatsSkeleton(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final r in _Range.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_rangeLabel(r, context)),
                      selected: _range == r,
                      onSelected: (_) => setState(() => _range = r),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Zero tags anywhere → a single inline discoverability hint replaces
          // the filter bar (§8.2). Otherwise the real filter bar.
          if (tagsExist)
            _TagFilterBar(
              tags: ([...allTags]..sort((a, b) {
                    final c = (tagCounts[b.id] ?? 0).compareTo(tagCounts[a.id] ?? 0);
                    return c != 0
                        ? c
                        : a.name.toLowerCase().compareTo(b.name.toLowerCase());
                  }))
                  .take(12)
                  .toList(),
              hasMore: allTags.length > 12,
              selected: selected,
              onToggle: toggle,
              onClear: () => setFilter(const []),
              onOpenPicker: () => showTagPickerSheet(
                context,
                selected: selected,
                onChanged: setFilter,
                maxSelection: 3,
                filterMode: true,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                l10n.tagsHintStats,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 16),
          if (tagsExist) ...[
            Text(
              filterActive ? l10n.onlyTags(headerNames) : l10n.allTags,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
          ],
          AnimatedSwitcher(
            duration:
                motion.reduced ? Duration.zero : const Duration(milliseconds: 180),
            child: body,
          ),
        ],
      ),
    );
  }
}

/// The Stats tag filter strip (§7.1): a wrapping row of filter chips (most-used
/// first, up to 12 then an "All tags…" chip) with a right-aligned clear button.
class _TagFilterBar extends StatelessWidget {
  const _TagFilterBar({
    required this.tags,
    required this.hasMore,
    required this.selected,
    required this.onToggle,
    required this.onClear,
    required this.onOpenPicker,
  });

  final List<Tag> tags;
  final bool hasMore;
  final List<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onClear;
  final VoidCallback onOpenPicker;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final atCap = selected.length >= 3;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in tags)
                TagChip(
                  label: t.name,
                  variant: TagChipVariant.filter,
                  dot: t.dot,
                  selected: selected.contains(t.id),
                  disabled: atCap && !selected.contains(t.id),
                  onTap: () => onToggle(t.id),
                ),
              if (hasMore)
                TagChip(
                  label: l10n.allTags,
                  variant: TagChipVariant.filter,
                  onTap: onOpenPicker,
                ),
            ],
          ),
          if (atCap) ...[
            const SizedBox(height: 8),
            Text(
              l10n.maxTagsFilter,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
          if (selected.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onClear,
                child: Text(l10n.tagsClear),
              ),
            ),
        ],
      ),
    );
  }
}

/// Skeleton for the Stats deck card (MOTION_HANDOFF §4.3).
class _StatsSkeleton extends StatelessWidget {
  const _StatsSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cw = constraints.maxWidth - 32; // 16 padding each side
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SkeletonBlock(width: cw * 0.34, height: 12),
            const SizedBox(height: 12),
            // Chart card with an inner baseline at 60% height.
            SizedBox(
              width: cw,
              height: 168,
              child: Stack(
                children: [
                  const Positioned.fill(
                    child: SkeletonBlock(height: 168, radius: 16),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 168 * 0.6,
                    child: Container(
                      height: 1,
                      color: theme.colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                SkeletonBlock(width: 64, height: 32, radius: 12),
                SizedBox(width: 8),
                SkeletonBlock(width: 88, height: 32, radius: 12),
                SizedBox(width: 8),
                SkeletonBlock(width: 72, height: 32, radius: 12),
              ],
            ),
            const SizedBox(height: 24),
            _SkeletonSummaryRow(contentWidth: cw),
            _SkeletonSummaryRow(contentWidth: cw),
          ],
        );
      },
    );
  }
}

class _SkeletonSummaryRow extends StatelessWidget {
  const _SkeletonSummaryRow({required this.contentWidth});

  final double contentWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SkeletonBlock(width: contentWidth * 0.40, height: 16),
          SkeletonBlock(width: contentWidth * 0.22, height: 16),
        ],
      ),
    );
  }
}

/// A titled, bordered container that gives each stats block breathing room.
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _LineChartBox extends StatelessWidget {
  const _LineChartBox({
    required this.series,
    required this.base,
    required this.locale,
  });
  final List<TimePoint> series;
  final String base;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final last = series.last.cumulativeBase;
    final color = context.money.forAmount(last);
    final spots = [
      for (var i = 0; i < series.length; i++)
        FlSpot(i.toDouble(), series[i].cumulativeBase),
    ];

    // Pad the value axis and always include the zero baseline.
    final values = series.map((p) => p.cumulativeBase).toList();
    var minV = values.reduce(math.min);
    var maxV = values.reduce(math.max);
    minV = math.min(minV, 0);
    maxV = math.max(maxV, 0);
    final pad = math.max((maxV - minV) * 0.12, 1.0);
    final minY = minV - pad;
    final maxY = maxV + pad;
    final yInterval = math.max((maxY - minY) / 4, 1.0);
    final labelStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    // Pad the x-axis a touch so the first/last date labels aren't clipped at
    // the chart edges, and place labels on whole-index ticks.
    final lastIndex = (series.length - 1).toDouble();
    final xPad = math.max(lastIndex * 0.04, 0.2);
    final xInterval = math.max((lastIndex / 3).ceilToDouble(), 1.0);

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          minY: minY,
          maxY: maxY,
          minX: -xPad,
          maxX: lastIndex + xPad,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: yInterval,
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                interval: xInterval,
                getTitlesWidget: (value, meta) {
                  // Only label whole-index ticks that map to a real point.
                  if ((value - value.roundToDouble()).abs() > 0.02) {
                    return const SizedBox();
                  }
                  final i = value.round();
                  if (i < 0 || i >= series.length) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(formatDayShort(series[i].date, locale),
                        style: labelStyle),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: yInterval,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(_axisLabel(value, locale), style: labelStyle),
                ),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.25,
              barWidth: 3,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.20),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  const _MonthlyBarChart({
    required this.data,
    required this.base,
    required this.locale,
    this.showTracks = false,
  });
  final List<MonthlyNet> data;
  final String base;
  final String locale;

  /// Draw a faint full-height background track behind every bar so that months
  /// with no matching entry read as empty slots under an active filter (§7.2).
  final bool showTracks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = context.money;
    final maxAbs = data
        .map((m) => m.netBase.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);
    final labelStyle = theme.textTheme.bodySmall
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);

    return SizedBox(
      height: 180,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxAbs,
          minY: -maxAbs,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxAbs,
            getDrawingHorizontalLine: (v) => FlLine(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: maxAbs,
                getTitlesWidget: (value, meta) => SideTitleWidget(
                  meta: meta,
                  space: 6,
                  child: Text(_axisLabel(value, locale), style: labelStyle),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 26,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return SideTitleWidget(
                    meta: meta,
                    space: 8,
                    child: Text(
                      formatMonth(data[i].month, locale).split(' ').first,
                      style: labelStyle,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < data.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: data[i].netBase,
                    width: 14,
                    borderRadius: BorderRadius.circular(4),
                    color: data[i].netBase >= 0 ? money.profit : money.loss,
                    backDrawRodData: showTracks
                        ? BackgroundBarChartRodData(
                            show: true,
                            fromY: -maxAbs,
                            toY: maxAbs,
                            color: theme.colorScheme.surfaceContainerHighest,
                          )
                        : BackgroundBarChartRodData(),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// Per-site horizontal bar breakdown ("Pr. spillested"): each site's net as a
/// proportional bar coloured by profit/loss, with the value on the right.
class _SiteBreakdown extends StatelessWidget {
  const _SiteBreakdown({
    required this.sites,
    required this.summaries,
    required this.rates,
    required this.base,
    required this.locale,
  });

  final List<Site> sites;
  final Map<String, SiteSummary> summaries;
  final Map<String, double> rates;
  final String base;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = context.money;
    final byId = {for (final s in sites) s.id: s};
    final rows = summaries.values
        .where((s) => byId.containsKey(s.siteId))
        .map((s) => (
              site: byId[s.siteId]!,
              netBase: convertMinorToBase(s.netMinor, s.currencyCode, rates),
            ))
        .toList()
      ..sort((a, b) => b.netBase.compareTo(a.netBase));
    if (rows.isEmpty) return const SizedBox.shrink();
    final maxAbs =
        rows.map((r) => r.netBase.abs()).fold<double>(1, math.max);

    return Column(
      children: [
        for (final r in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 92,
                  child: Text(
                    r.site.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: (r.netBase.abs() / maxAbs).clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                      color: money.forAmount(r.netBase),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 74,
                  child: Text(
                    formatMinorPlain(
                      (r.netBase * 100).round(),
                      localeName: locale,
                      withSign: true,
                    ),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: money.forAmount(r.netBase),
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Best / worst site shown as two filled containers (green / red).
class _BestWorstCards extends StatelessWidget {
  const _BestWorstCards({
    required this.sites,
    required this.summaries,
    required this.rates,
    required this.base,
    required this.locale,
    this.filtered = false,
  });

  final List<Site> sites;
  final Map<String, SiteSummary> summaries;
  final Map<String, double> rates;
  final String base;
  final String locale;

  /// Under a tag filter a single matching site shows one card, never an
  /// invented second (§7.2). Unfiltered keeps the original two-card layout.
  final bool filtered;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final money = context.money;
    final byId = {for (final s in sites) s.id: s};
    final withNet = summaries.values
        .where((s) => byId.containsKey(s.siteId))
        .map((s) => (
              site: byId[s.siteId]!,
              netBase: convertMinorToBase(s.netMinor, s.currencyCode, rates),
            ))
        .toList()
      ..sort((a, b) => b.netBase.compareTo(a.netBase));
    if (withNet.isEmpty) return const SizedBox.shrink();

    final best = withNet.first;
    final worst = withNet.last;

    Widget card({
      required String label,
      required String name,
      required double net,
      required Color bg,
      required Color fg,
    }) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: fg.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(color: fg, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                formatMajorSmart(net, base, localeName: locale, withSign: true),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: fg,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
              ),
            ],
          ),
        ),
      );
    }

    // Under a filter with a single matching site, show one card only — a best
    // and worst drawn from the same site would be a fabricated comparison.
    final single = filtered && withNet.length < 2;

    // IntrinsicHeight bounds the cross-axis so the two cards can stretch to
    // equal height without an unbounded-height error inside the ListView.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          card(
            label: l10n.statsBestSite,
            name: best.site.name,
            net: best.netBase,
            bg: money.profitContainer,
            fg: money.onProfitContainer,
          ),
          if (!single) ...[
            const SizedBox(width: 12),
            card(
              label: l10n.statsWorstSite,
              name: worst.site.name,
              net: worst.netBase,
              bg: money.lossContainer,
              fg: money.onLossContainer,
            ),
          ],
        ],
      ),
    );
  }
}
