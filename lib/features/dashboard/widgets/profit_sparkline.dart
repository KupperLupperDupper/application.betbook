import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/stats/summaries.dart';
import '../../../core/theme/money_colors.dart';

/// A minimal, axis-less cumulative-profit line for the dashboard hero area.
class ProfitSparkline extends StatelessWidget {
  const ProfitSparkline({super.key, required this.points, this.height = 64});

  final List<TimePoint> points;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (points.length < 2) return SizedBox(height: height);

    final last = points.last.cumulativeBase;
    final color = context.money.forAmount(last);

    final spots = [
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].cumulativeBase),
    ];

    return SizedBox(
      height: height,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: const FlTitlesData(show: false),
          borderData: FlBorderData(show: false),
          lineTouchData: const LineTouchData(enabled: false),
          minX: 0,
          maxX: (points.length - 1).toDouble(),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.28,
              barWidth: 2.5,
              color: color,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    color.withValues(alpha: 0.22),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 350),
      ),
    );
  }
}
