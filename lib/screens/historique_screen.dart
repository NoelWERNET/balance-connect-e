import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mesure.dart';
import '../services/storage_service.dart';

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
    final mesures = await _storage.chargerHistorique();
    setState(() {
      _mesures = mesures;
      _chargement = false;
    });
  }

  Future<void> _supprimer(int index) async {
    final liste = List<Mesure>.from(_mesures)..removeAt(index);
    await _storage.sauvegarderListeMesures(liste);
    setState(() => _mesures = liste);
  }

  Future<void> _viderTout() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider l\'historique'),
        content: const Text('Supprimer toutes les mesures ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Non')),
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Oui')),
        ],
      ),
    );
    if (confirme == true) {
      await _storage.viderHistorique();
      setState(() => _mesures = []);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF36B5FF),
        title: const Text('Historique des mesures'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            tooltip: 'Vider tout',
            onPressed: _mesures.isNotEmpty ? _viderTout : null,
          ),
        ],
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : _mesures.isEmpty
              ? const Center(child: Text('Aucune mesure enregistrée'))
              : ListView.builder(
                  itemCount: _mesures.length,
                  itemBuilder: (_, i) {
                    final m = _mesures[i];
                    return ListTile(
                      leading: const Icon(Icons.straighten),
                      title: Text('${m.poids.toStringAsFixed(2)} g'),
                      subtitle: Text(
                          DateFormat('dd/MM/yyyy HH:mm:ss').format(m.dateHeure)),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _supprimer(i),
                      ),
                    );
                  },
                ),
    );
  }
}
