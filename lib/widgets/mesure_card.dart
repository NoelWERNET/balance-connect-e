import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mesure.dart';

/// Carte affichant une mesure avec sa valeur en kg et son horodatage.
class MesureCard extends StatelessWidget {
  final Mesure mesure;
  final int index;

  const MesureCard({
    super.key,
    required this.mesure,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final formatter = DateFormat('dd/MM/yyyy HH:mm:ss');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primaryContainer,
          child: Text(
            '$index',
            style: TextStyle(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          '${mesure.valeur.toStringAsFixed(3)} kg',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Text(
          formatter.format(mesure.horodatage),
          style: theme.textTheme.bodySmall,
        ),
        trailing: Icon(
          Icons.monitor_weight_outlined,
          color: theme.colorScheme.secondary,
        ),
      ),
    );
  }
}
