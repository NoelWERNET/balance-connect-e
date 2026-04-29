import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement.dart';

/// Graphique linéaire affichant l'évolution du poids dans le temps.
class WeightChart extends StatelessWidget {
  final List<Measurement> measurements;

  const WeightChart({super.key, required this.measurements});

  @override
  Widget build(BuildContext context) {
    if (measurements.isEmpty) {
      return const Center(
        child: Text('Aucune mesure enregistrée.'),
      );
    }

    // Les mesures sont stockées en ordre décroissant ; on les inverse
    // pour l'axe X (le plus ancien à gauche).
    final sorted = measurements.reversed.toList();

    final spots = sorted.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.value);
    }).toList();

    final minY = sorted.map((m) => m.value).reduce((a, b) => a < b ? a : b);
    final maxY = sorted.map((m) => m.value).reduce((a, b) => a > b ? a : b);
    final padding = (maxY - minY) * 0.1 + 50;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 24, 16),
      child: LineChart(
        LineChartData(
          minY: (minY - padding).clamp(0, double.infinity),
          maxY: maxY + padding,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Theme.of(context).colorScheme.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: sorted.length <= 30,
              ),
              belowBarData: BarAreaData(
                show: true,
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withAlpha(40),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              axisNameWidget: const Text('Poids (g)',
                  style: TextStyle(fontSize: 11)),
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 52,
                getTitlesWidget: (value, meta) => Text(
                  value.toStringAsFixed(0),
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                interval: (sorted.length / 5).ceilToDouble().clamp(1, 999),
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx < 0 || idx >= sorted.length) {
                    return const SizedBox.shrink();
                  }
                  final dt = sorted[idx].timestamp;
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      DateFormat('HH:mm\ndd/MM').format(dt),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 9),
                    ),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: const FlGridData(show: true),
          borderData: FlBorderData(show: true),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((s) {
                  final m = sorted[s.x.toInt()];
                  final label = m.value >= 1000
                      ? '${(m.value / 1000).toStringAsFixed(3)} kg'
                      : '${m.value.toStringAsFixed(1)} g';
                  final dateStr =
                      DateFormat('dd/MM HH:mm').format(m.timestamp);
                  return LineTooltipItem(
                    '$label\n$dateStr',
                    const TextStyle(fontSize: 11),
                  );
                }).toList();
              },
            ),
          ),
        ),
      ),
    );
  }
}
