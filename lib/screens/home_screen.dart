import 'dart:async';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/mesure.dart';
import '../services/bluetooth_service.dart';
import '../services/storage_service.dart';
import 'historique_screen.dart';
import 'courbe_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothService _btService = BluetoothService();
  final StorageService _storage = StorageService();

  String _messageDernier = '';
  double? _poidsBrut;
  double _tare = 0.0;
  String _etiquetteStatut = 'Déconnecté';
  Color _couleurStatut = Colors.red;

  late StreamSubscription<String> _abonnementMessages;

  @override
  void initState() {
    super.initState();
    _abonnementMessages = _btService.messages.listen(_onMessageRecu);
    _btService.etat.addListener(_onEtatChange);
    _demanderPermissions();
  }

  Future<void> _demanderPermissions() async {
    await _btService.demanderPermissions();
  }

  void _onEtatChange() {
    final etat = _btService.etat.value;
    setState(() {
      switch (etat) {
        case EtatBluetooth.connecte:
          _etiquetteStatut = 'Connecté';
          _couleurStatut = Colors.green;
        case EtatBluetooth.connexionEnCours:
          _etiquetteStatut = 'Connexion…';
          _couleurStatut = Colors.orange;
        case EtatBluetooth.deconnecte:
          _etiquetteStatut = 'Déconnecté';
          _couleurStatut = Colors.red;
        case EtatBluetooth.erreur:
          _etiquetteStatut = 'Erreur';
          _couleurStatut = Colors.red;
      }
    });
  }

  void _onMessageRecu(String message) {
    setState(() {
      _messageDernier = message;
      final valeur = double.tryParse(message.replaceAll(',', '.'));
      if (valeur != null) {
        _poidsBrut = valeur;
      }
    });
  }

  double get _poidsNet => (_poidsBrut ?? 0.0) - _tare;

  Future<void> _selectionnerAppareil() async {
    final appareils = await _btService.appareilsAppaires();
    if (!mounted) return;

    if (appareils.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun appareil Bluetooth appairé trouvé')),
      );
      return;
    }

    final Device? choix = await showDialog<Device>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Choisir un appareil'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: appareils.length,
            itemBuilder: (_, i) => ListTile(
              leading: const Icon(Icons.bluetooth),
              title: Text(appareils[i].name ?? 'Inconnu'),
              subtitle: Text(appareils[i].address),
              onTap: () => Navigator.of(ctx).pop(appareils[i]),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Annuler'),
          ),
        ],
      ),
    );

    if (choix != null) {
      try {
        await _btService.connecter(choix.address);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur de connexion : $e')),
          );
        }
      }
    }
  }

  Future<void> _deconnecter() async {
    await _btService.deconnecter();
  }

  Future<void> _initialiser() async {
    setState(() => _tare = 0.0);
    await _btService.envoyerCommande('0');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initialisation — placez le poids')),
      );
    }
  }

  Future<void> _tarer() async {
    setState(() => _tare = _poidsBrut ?? 0.0);
    await _btService.envoyerCommande('1');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tarage en cours…')),
      );
    }
  }

  Future<void> _demanderMesure() async {
    await _btService.envoyerCommande('2');
  }

  Future<void> _sauvegarderMesure() async {
    if (_poidsBrut == null) return;
    final mesure = Mesure(poids: _poidsNet, dateHeure: DateTime.now());
    await _storage.sauvegarderMesure(mesure);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Mesure sauvegardée : ${_poidsNet.toStringAsFixed(2)} g — '
            '${DateFormat('dd/MM/yyyy HH:mm').format(mesure.dateHeure)}',
          ),
        ),
      );
    }
  }

  Future<void> _viderListe() async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider la liste'),
        content: const Text('Voulez-vous supprimer tout l\'historique ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui'),
          ),
        ],
      ),
    );
    if (confirme == true) {
      await _storage.viderHistorique();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Historique vidé')),
        );
      }
    }
  }

  @override
  void dispose() {
    _abonnementMessages.cancel();
    _btService.etat.removeListener(_onEtatChange);
    _btService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estConnecte = _btService.etat.value == EtatBluetooth.connecte;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF36B5FF),
        title: const Text('Balance Connectée'),
        actions: [
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Courbe',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CourbeScreen(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Historique',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HistoriqueScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Statut Bluetooth
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.bluetooth, color: _couleurStatut),
                    const SizedBox(width: 8),
                    Text(
                      _etiquetteStatut,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontStyle: FontStyle.italic,
                        fontSize: 16,
                        color: _couleurStatut,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.bluetooth_searching),
                      tooltip: 'Connecter',
                      onPressed: _selectionnerAppareil,
                    ),
                    if (estConnecte)
                      IconButton(
                        icon: const Icon(Icons.bluetooth_disabled),
                        tooltip: 'Déconnecter',
                        onPressed: _deconnecter,
                      ),
                  ],
                ),
              ],
            ),

            const Divider(),

            // Message reçu
            Row(
              children: [
                const Text('Message reçu : '),
                Expanded(
                  child: Text(
                    _messageDernier,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Affichage poids / mesure nette
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Poids brut (g)',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          _poidsBrut != null
                              ? _poidsBrut!.toStringAsFixed(2)
                              : '--',
                          style: const TextStyle(
                              fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text('Mesure nette (g)',
                            style: TextStyle(fontSize: 12)),
                        Text(
                          _poidsBrut != null
                              ? _poidsNet.toStringAsFixed(2)
                              : '--',
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Boutons commandes
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 2.5,
              children: [
                ElevatedButton.icon(
                  onPressed: estConnecte ? _initialiser : null,
                  icon: const Icon(Icons.restart_alt),
                  label: const Text('Initialisation'),
                ),
                ElevatedButton.icon(
                  onPressed: estConnecte ? _tarer : null,
                  icon: const Icon(Icons.filter_center_focus),
                  label: const Text('Tarer'),
                ),
                ElevatedButton.icon(
                  onPressed: estConnecte ? _demanderMesure : null,
                  icon: const Icon(Icons.straighten),
                  label: const Text('Demande mesure'),
                ),
                ElevatedButton.icon(
                  onPressed: estConnecte ? _sauvegarderMesure : null,
                  icon: const Icon(Icons.save),
                  label: const Text('Sauvegarder'),
                ),
              ],
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: _viderListe,
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
              label: const Text('Vider liste',
                  style: TextStyle(color: Colors.red)),
            ),

            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const HistoriqueScreen()),
              ),
              icon: const Icon(Icons.list),
              label: const Text('Liste des poids'),
            ),

            const SizedBox(height: 16),
            const Text(
              '© 2026 Wernet. Tous droits réservés',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
