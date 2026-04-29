import 'package:flutter/material.dart';

import '../models/mesure.dart';
import '../services/storage_service.dart';
import '../widgets/mesure_card.dart';
import 'courbe_screen.dart';

/// Écran historique : liste de toutes les mesures stockées.
class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
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

  Future<void> _supprimerPlusVieille() async {
    if (_mesures.isEmpty) return;
    final confirmation = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la plus vieille mesure'),
        content: const Text(
          'Voulez-vous supprimer la mesure la plus ancienne de la liste ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmation == true) {
      final nouvelleListe = await _storage.supprimerPlusVieille();
      if (mounted) setState(() => _mesures = nouvelleListe);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des mesures'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Courbe du poids',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CourbeScreen()),
            ),
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _mesures.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.inbox_outlined,
                        size: 64,
                        color: theme.colorScheme.outline,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Aucune mesure enregistrée',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: _mesures.length,
                  itemBuilder: (ctx, i) => MesureCard(
                    mesure: _mesures[i],
                    index: i + 1,
                  ),
                ),
      bottomNavigationBar: _mesures.isNotEmpty
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_mesures.length} mesure(s) — max ${StorageService.maxMesures}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: _supprimerPlusVieille,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Supprimer la plus vieille'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: theme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
