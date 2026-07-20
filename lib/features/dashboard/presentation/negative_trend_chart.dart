import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../domain/dashboard_summary.dart';

/// Negatif yorum trendini gösteren alan grafiği (area line chart).
///
/// fl_chart kullanıyor - önceki elle çizilen çubuk grafiğin yerine geçti.
/// Yumuşak eğri (isCurved), altında gölgeli dolgu, en yüksek noktada vurgu.
///
/// Renk kırmızı: negatif yorum bir uyarı göstergesi, temanın mavisiyle
/// değil hata rengiyle çiziliyor - kullanıcı "kötü giden bir şey" algısını
/// anında alsın.
class NegativeTrendChart extends StatelessWidget {
  const NegativeTrendChart({super.key, required this.data});

  final List<DailyNegativeCount> data;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final lineColor = scheme.error;

    // fl_chart x eksenini sayısal ister; günleri 0,1,2... indeksliyoruz.
    final spots = <FlSpot>[
      for (var i = 0; i < data.length; i++)
        FlSpot(i.toDouble(), data[i].count.toDouble()),
    ];

    // Y ekseni üst sınırı: en yüksek değerin biraz üstü (nefes alsın).
    final maxCount =
        data.map((d) => d.count).fold<int>(0, (a, b) => a > b ? a : b);
    final maxY = (maxCount + 1).toDouble();

    return SizedBox(
      height: 160,
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: (data.length - 1).toDouble(),
          minY: 0,
          maxY: maxY,
          // --- Izgara ---
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: scheme.outlineVariant.withValues(alpha: 0.3),
              strokeWidth: 1,
            ),
          ),
          // --- Kenarlıklar ---
          borderData: FlBorderData(show: false),
          // --- Eksen etiketleri ---
          titlesData: FlTitlesData(
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: maxY <= 4 ? 1 : (maxY / 4).ceilToDouble(),
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
              getTooltipColor: (_) => scheme.error,
              getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                return LineTooltipItem(
                  '${spot.y.toInt()} negatif',
                  TextStyle(
                    color: scheme.onError,
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
                  // Sadece en yüksek noktayı vurgula.
                  final isPeak = spot.y == maxCount.toDouble();
                  return FlDotCirclePainter(
                    radius: isPeak ? 5 : 0,
                    color: lineColor,
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