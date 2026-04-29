import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/storage_service.dart';
import '../widgets/measurement_tile.dart';
import 'chart_screen.dart';

/// Écran affichant la liste des mesures enregistrées.
///
/// • Bouton « Supprimer la plus ancienne » pour ne retirer que la plus
///   vieille valeur (comportement demandé par l'utilisateur).
/// • Bouton « Courbe du poids » pour naviguer vers le graphique.
/// • Possibilité de tout effacer via le menu (kebab).
class MeasurementsScreen extends StatelessWidget {
  const MeasurementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StorageService>(
      builder: (context, storage, _) {
        final measurements = storage.measurements;

        return Scaffold(
          appBar: AppBar(
            title: Text(
                'Mesures (${measurements.length})'),
            actions: [
              // Bouton courbe du poids
              IconButton(
                icon: const Icon(Icons.show_chart),
                tooltip: 'Courbe du poids',
                onPressed: measurements.isEmpty
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const ChartScreen(),
                          ),
                        ),
              ),
              // Menu kebab
              PopupMenuButton<_MenuAction>(
                onSelected: (action) =>
                    _onMenuSelected(context, action, storage),
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: _MenuAction.deleteOldest,
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep_outlined),
                      title: Text('Supprimer la plus ancienne'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  PopupMenuItem(
                    value: _MenuAction.clearAll,
                    child: ListTile(
                      leading: Icon(Icons.delete_forever_outlined,
                          color: Colors.red),
                      title: Text('Tout effacer',
                          style: TextStyle(color: Colors.red)),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: measurements.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.scale_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Aucune mesure enregistrée.\nPrenez une mesure depuis l\'écran principal.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Bannière d'action rapide
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _confirmDeleteOldest(
                                  context, storage),
                              icon: const Icon(Icons.delete_sweep_outlined),
                              label:
                                  const Text('Supprimer la plus ancienne'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ChartScreen(),
                              ),
                            ),
                            icon: const Icon(Icons.show_chart),
                            label: const Text('Courbe'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: ListView.builder(
                        itemCount: measurements.length,
                        itemBuilder: (_, i) {
                          final m = measurements[i];
                          final isOldest = i == measurements.length - 1;
                          return MeasurementTile(
                            measurement: m,
                            isOldest: isOldest,
                            onDelete: () =>
                                _confirmDelete(context, storage, i),
                          );
                        },
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  void _onMenuSelected(
    BuildContext context,
    _MenuAction action,
    StorageService storage,
  ) {
    switch (action) {
      case _MenuAction.deleteOldest:
        _confirmDeleteOldest(context, storage);
        break;
      case _MenuAction.clearAll:
        _confirmClearAll(context, storage);
        break;
    }
  }

  Future<void> _confirmDeleteOldest(
      BuildContext context, StorageService storage) async {
    if (storage.measurements.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer la plus ancienne ?'),
        content: const Text(
            'La mesure la plus ancienne sera définitivement supprimée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true) await storage.deleteOldest();
  }

  Future<void> _confirmDelete(
      BuildContext context, StorageService storage, int index) async {
    final measurements = storage.measurements;
    if (index >= measurements.length) return;
    final m = measurements[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Supprimer cette mesure ?'),
        content: Text('Valeur : ${m.value} g\n'
            'Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer')),
        ],
      ),
    );
    if (confirm == true && m.id != null) {
      await storage.deleteById(m.id!);
    }
  }

  Future<void> _confirmClearAll(
      BuildContext context, StorageService storage) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Tout effacer ?'),
        content: const Text(
            'Toutes les mesures seront définitivement supprimées.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Effacer tout')),
        ],
      ),
    );
    if (confirm == true) await storage.clearAll();
  }
}

enum _MenuAction { deleteOldest, clearAll }
