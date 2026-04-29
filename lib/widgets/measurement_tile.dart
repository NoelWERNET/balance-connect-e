import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/measurement.dart';

/// Tuile affichant une mesure dans la liste.
class MeasurementTile extends StatelessWidget {
  final Measurement measurement;
  final VoidCallback? onDelete;
  final bool isOldest;

  const MeasurementTile({
    super.key,
    required this.measurement,
    this.onDelete,
    this.isOldest = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateStr =
        DateFormat('dd/MM/yyyy HH:mm:ss').format(measurement.timestamp);
    final valueStr = _formatValue(measurement.value);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isOldest
              ? theme.colorScheme.errorContainer
              : theme.colorScheme.primaryContainer,
          child: Icon(
            Icons.monitor_weight_outlined,
            color: isOldest
                ? theme.colorScheme.onErrorContainer
                : theme.colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          valueStr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          dateStr,
          style: theme.textTheme.bodySmall,
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_outline),
                tooltip: 'Supprimer',
                onPressed: onDelete,
              )
            : null,
      ),
    );
  }

  /// Formate la valeur : grammes si < 1000 g, sinon kilogrammes.
  String _formatValue(double grams) {
    if (grams >= 1000) {
      return '${(grams / 1000).toStringAsFixed(3)} kg';
    }
    return '${grams.toStringAsFixed(1)} g';
  }
}
