import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money/money_format.dart';
import '../../core/stats/summaries.dart';
import '../../core/theme/money_colors.dart';
import '../../core/utils/date_format.dart';
import '../../data/database/database.dart';
import '../../l10n/l10n_ext.dart';
import '../../providers/data_providers.dart';
import '../../providers/settings_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/net_text.dart';

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
    final sites = ref.watch(sitesProvider).valueOrNull ?? const <Site>[];
    final txs = ref.watch(allTransactionsProvider).valueOrNull ??
        const <Transaction>[];
    final rates = ref.watch(rateMapProvider);

    if (txs.length < 2) {
      return EmptyState(
        icon: Icons.insights_rounded,
        title: l10n.statsNoData,
        message: l10n.statsNoDataBody,
      );
    }

    final from = _from();
    final series = buildCumulativeSeries(
      sites: sites,
      transactions: txs,
      rateToBase: rates,
      baseCurrency: base,
      from: from,
    );
    final monthly = buildMonthlyNet(
      sites: sites,
      transactions: txs,
      rateToBase: rates,
      baseCurrency: base,
      from: from,
    );
    final rangeNet = series.isEmpty ? 0.0 : series.last.cumulativeBase;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
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
        const SizedBox(height: 16),
        Text(l10n.statsNetResult,
            style: theme.textTheme.labelLarge
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text(
          formatMajor(rangeNet, base, localeName: locale, withSign: true),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: context.money.forAmount(rangeNet),
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 20),
        if (series.length >= 2) ...[
          Text(l10n.dashboardProfitOverTime,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _LineChartBox(series: series, base: base, locale: locale),
          const SizedBox(height: 28),
        ],
        if (monthly.isNotEmpty) ...[
          Text(l10n.statsByMonth,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          _MonthlyBarChart(data: monthly, base: base, locale: locale),
          const SizedBox(height: 28),
        ],
        _BestWorst(
          sites: sites,
          summaries: ref.watch(portfolioProvider)?.siteSummaries ?? const {},
          rates: rates,
          base: base,
          locale: locale,
        ),
      ],
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

    return SizedBox(
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: null,
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
                reservedSize: 22,
                interval: (series.length / 3).clamp(1, series.length).toDouble(),
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= series.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatDayShort(series[i].date, locale),
                      style: theme.textTheme.bodySmall,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  formatCompactMajor(value, base, localeName: locale),
                  style: theme.textTheme.bodySmall,
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
  });
  final List<MonthlyNet> data;
  final String base;
  final String locale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final money = context.money;
    final maxAbs = data
        .map((m) => m.netBase.abs())
        .fold<double>(1, (a, b) => a > b ? a : b);

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
                reservedSize: 44,
                getTitlesWidget: (value, meta) => Text(
                  formatCompactMajor(value, base, localeName: locale),
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= data.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatMonth(data[i].month, locale).split(' ').first,
                      style: theme.textTheme.bodySmall,
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
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _BestWorst extends StatelessWidget {
  const _BestWorst({
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
    final l10n = context.l10n;
    if (summaries.isEmpty || sites.isEmpty) return const SizedBox.shrink();

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

    Widget row(String label, String name, double net) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              NetText(
                value: net,
                text: formatMajor(net, base, localeName: locale, withSign: true),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row(l10n.statsBestSite, best.site.name, best.netBase),
        if (worst.site.id != best.site.id)
          row(l10n.statsWorstSite, worst.site.name, worst.netBase),
      ],
    );
  }
}
