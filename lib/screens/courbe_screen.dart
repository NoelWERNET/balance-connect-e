import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mesure.dart';
import '../services/storage_service.dart';

/// Écran courbe : graphique de l'évolution du poids dans le temps.
class CourbeScreen extends StatefulWidget {
  const CourbeScreen({super.key});

  @override
  State<CourbeScreen> createState() => _CourbeScreenState();
}

class _CourbeScreenState extends State<CourbeScreen> {
  final StorageService _storage = StorageService();
  List<Mesure> _mesures = [];
  bool _chargement = true;

  @override
  void initState() {
    super.initState();
    _charger();
  }

  Future<void> _charger() async {
    setState(() => _chargement = true);
    final liste = await _storage.chargerMesures();
    if (mounted) {
      setState(() {
        _mesures = liste;
        _chargement = false;
      });
    }
  }

  List<FlSpot> _points() {
    if (_mesures.isEmpty) return [];
    final debut = _mesures.first.horodatage.millisecondsSinceEpoch.toDouble();
    return _mesures.asMap().entries.map((e) {
      final x =
          (e.value.horodatage.millisecondsSinceEpoch.toDouble() - debut) /
              60000; // minutes depuis la première mesure
      return FlSpot(x, e.value.valeur);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final points = _points();

    double minY = 0;
    double maxY = 10;
    if (_mesures.isNotEmpty) {
      final valeurs = _mesures.map((m) => m.valeur).toList();
      minY = (valeurs.reduce((a, b) => a < b ? a : b) - 0.5)
          .clamp(0.0, double.infinity);
      maxY = valeurs.reduce((a, b) => a > b ? a : b) + 0.5;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Courbe du poids'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualiser',
            onPressed: _charger,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _mesures.length < 2
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Pas assez de données\n(minimum 2 mesures)',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${_mesures.length} mesure(s)',
                        style: theme.textTheme.labelMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Abscisse : minutes depuis la 1re mesure\n'
                        'Ordonnée : poids (kg)',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            minY: minY,
                            maxY: maxY,
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: true,
                              getDrawingHorizontalLine: (v) => FlLine(
                                color: theme.colorScheme.outlineVariant
                                    .withOpacity(0.5),
                                strokeWidth: 1,
                              ),
                              getDrawingVerticalLine: (v) => FlLine(
                                color: theme.colorScheme.outlineVariant
                                    .withOpacity(0.5),
                                strokeWidth: 1,
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                axisNameWidget: const Text('kg'),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 48,
                                  getTitlesWidget: (v, meta) => Text(
                                    v.toStringAsFixed(2),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                axisNameWidget: const Text('min'),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 30,
                                  getTitlesWidget: (v, meta) => Text(
                                    v.toStringAsFixed(0),
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(
                              show: true,
                              border: Border.all(
                                color: theme.colorScheme.outline,
                              ),
                            ),
                            lineBarsData: [
                              LineChartBarData(
                                spots: points,
                                isCurved: true,
                                color: theme.colorScheme.primary,
                                barWidth: 3,
                                dotData: FlDotData(
                                  show: true,
                                  getDotPainter: (spot, _, __, ___) =>
                                      FlDotCirclePainter(
                                    radius: 4,
                                    color: theme.colorScheme.primary,
                                    strokeColor:
                                        theme.colorScheme.primaryContainer,
                                    strokeWidth: 2,
                                  ),
                                ),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color: theme.colorScheme.primary
                                      .withOpacity(0.1),
                                ),
                              ),
                            ],
                            lineTouchData: LineTouchData(
                              touchTooltipData: LineTouchTooltipData(
                                getTooltipItems: (spots) => spots
                                    .map(
                                      (s) => LineTooltipItem(
                                        '${s.y.toStringAsFixed(3)} kg\n',
                                        TextStyle(
                                          color: theme.colorScheme
                                              .onPrimaryContainer,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: DateFormat('HH:mm:ss').format(
                                              _mesures[s.spotIndex].horodatage,
                                            ),
                                            style: TextStyle(
                                              color: theme.colorScheme
                                                  .onPrimaryContainer
                                                  .withOpacity(0.8),
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    .toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
