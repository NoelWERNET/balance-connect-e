import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../widgets/weight_chart.dart';

/// Écran de la courbe du poids.
class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Courbe du poids'),
        centerTitle: true,
      ),
      body: Consumer<StorageService>(
        builder: (context, storage, _) {
          final measurements = storage.measurements;
          if (measurements.isEmpty) {
            return const Center(
              child: Text('Aucune mesure à afficher.'),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${measurements.length} mesure(s)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    Text(
                      'Min : ${_fmt(measurements.map((m) => m.value).reduce((a, b) => a < b ? a : b))}'
                      '  Max : ${_fmt(measurements.map((m) => m.value).reduce((a, b) => a > b ? a : b))}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: WeightChart(measurements: measurements),
              ),
            ],
          );
        },
      ),
    );
  }

  String _fmt(double g) =>
      g >= 1000 ? '${(g / 1000).toStringAsFixed(3)} kg' : '${g.toStringAsFixed(1)} g';
}
