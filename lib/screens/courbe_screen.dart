import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mesure.dart';
import '../services/storage_service.dart';

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
    final mesures = await _storage.chargerHistorique();
    setState(() {
      _mesures = mesures;
      _chargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF36B5FF),
        title: const Text('Courbe des mesures'),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _mesures.isEmpty
              ? const Center(child: Text('Aucune donnée à afficher'))
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Évolution des mesures',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: true),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                axisNameWidget: const Text('Poids (g)'),
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 50,
                                  getTitlesWidget: (val, meta) => Text(
                                    val.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 10),
                                  ),
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 36,
                                  getTitlesWidget: (val, meta) {
                                    final index = val.toInt();
                                    if (index < 0 ||
                                        index >= _mesures.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return RotatedBox(
                                      quarterTurns: 1,
                                      child: Text(
                                        DateFormat('HH:mm').format(
                                            _mesures[index].dateHeure),
                                        style:
                                            const TextStyle(fontSize: 9),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles:
                                    SideTitles(showTitles: false),
                              ),
                            ),
                            borderData: FlBorderData(show: true),
                            lineBarsData: [
                              LineChartBarData(
                                spots: List.generate(
                                  _mesures.length,
                                  (i) => FlSpot(
                                      i.toDouble(), _mesures[i].poids),
                                ),
                                isCurved: true,
                                color: Colors.blue,
                                dotData: const FlDotData(show: true),
                                belowBarData: BarAreaData(
                                  show: true,
                                  color:
                                      Colors.blue.withValues(alpha: 0.1),
                                ),
                              ),
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
