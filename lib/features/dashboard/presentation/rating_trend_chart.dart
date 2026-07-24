import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/dashboard_summary.dart';

/// Günlük ortalama puan trendini gösteren alan grafiği (area line chart).
///
/// Y ekseni sabit 0-5 (puan skalası) - günden güne kıyaslanabilir olsun.
/// En düşük puanlı gün vurgulanır: düşen puan bir erken uyarı sinyali.
class RatingTrendChart extends StatelessWidget {
  const RatingTrendChart({super.key, required this.data});

  final List<DailyRatingPoint> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.primary;

    // fl_chart x eksenini sayısal ister; günleri 0,1,2... indeksliyoruz.
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].averageRating),
    ];

    final minRating = data
        .map((d) => d.averageRating)
        .fold<double>(5, (a, b) => a < b ? a : b);

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: 5,
          // --- Izgara ---
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          // --- Kenarlıklar ---
          borderData: FlBorderData(show: false),
          // --- Eksen etiketleri ---
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: 1,
                getTitlesWidget: (value, meta) => Text(
                  value.toInt().toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).hintColor,
                  ),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 24,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      _weekday(data[index].date),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).hintColor,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          // --- Dokunma / tooltip ---
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => lineColor,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                final point = data[spot.x.toInt()];
                return LineTooltipItem(
                  '${point.averageRating.toStringAsFixed(1)} ★\n'
                  '${point.reviewCount} yorum',
                  TextStyle(
                    color: scheme.onPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList(),
            ),
          ),
          // --- Çizgi ---
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true, // yumuşak eğri
              curveSmoothness: 0.3,
              color: lineColor,
              barWidth: 3,
              isStrokeCapRound: true,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, bar, index) {
                  // En düşük puanlı günü vurgula - erken uyarı sinyali.
                  final isLowPoint = spot.y == minRating;
                  return FlDotCirclePainter(
                    radius: isLowPoint ? 5 : 0,
                    color: isLowPoint ? scheme.error : lineColor,
                    strokeWidth: 2,
                    strokeColor: scheme.surface,
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    lineColor.withValues(alpha: 0.25),
                    lineColor.withValues(alpha: 0.02),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekday(DateTime date) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[date.weekday - 1];
  }
}
