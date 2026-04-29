import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import '../models/mesure.dart';
import '../services/bluetooth_service.dart';
import '../services/crypto_service.dart';
import '../services/storage_service.dart';
import 'historique_screen.dart';
import 'courbe_screen.dart';

/// Écran principal : connexion Bluetooth et commandes de la balance.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final BluetoothService _bt = BluetoothService();
  final CryptoService _crypto = CryptoService();
  final StorageService _storage = StorageService();

  List<BluetoothDevice> _appareils = [];
  BluetoothDevice? _appareilSelectionne;
  String _statutMessage = 'En attente…';
  double? _derniereMesure;
  bool _chargement = false;

  StreamSubscription<String>? _abonnementMessages;

  @override
  void initState() {
    super.initState();
    _bt.etat.addListener(_onEtatChange);
    _abonnementMessages = _bt.messages.listen(_onMessage);
    _initialiser();
  }

  Future<void> _initialiser() async {
    final ok = await _bt.demanderPermissions();
    if (!ok) {
      _setStatut('⚠️ Permissions Bluetooth refusées.');
      return;
    }
    await _chargerAppareils();
  }

  Future<void> _chargerAppareils() async {
    try {
      final liste = await _bt.appareilsAppaires();
      if (mounted) setState(() => _appareils = liste);
    } catch (e) {
      _setStatut('Erreur lors de la recherche des appareils : $e');
    }
  }

  void _onEtatChange() {
    if (!mounted) return;
    final etat = _bt.etat.value;
    setState(() {
      switch (etat) {
        case EtatBluetooth.connecte:
          _statutMessage = "✅ Connecté à ${_appareilSelectionne?.name ?? "l'appareil"}";
          _chargement = false;
        case EtatBluetooth.connexionEnCours:
          _statutMessage = '🔄 Connexion en cours…';
          _chargement = true;
        case EtatBluetooth.deconnecte:
          _statutMessage = '🔵 Déconnecté';
          _chargement = false;
        case EtatBluetooth.erreur:
          _statutMessage = '❌ Erreur de connexion';
          _chargement = false;
      }
    });
  }

  void _onMessage(String message) {
    if (!mounted) return;
    // Détecte si c'est une mesure encodée (Base64 AES) ou un message texte.
    final estMesure = _estBase64(message);
    if (estMesure) {
      try {
        final valeur = _crypto.decrypterMesure(message);
        final mesure = Mesure(valeur: valeur, horodatage: DateTime.now());
        _storage.ajouterMesure(mesure);
        setState(() {
          _derniereMesure = valeur;
          _statutMessage = '📏 Mesure reçue : ${valeur.toStringAsFixed(3)} kg';
        });
      } catch (e) {
        _setStatut('⚠️ Erreur de déchiffrement : $e');
      }
    } else {
      _setStatut('💬 Arduino : $message');
    }
  }

  bool _estBase64(String s) {
    final regex = RegExp(r'^[A-Za-z0-9+/=]+$');
    return regex.hasMatch(s) && s.length % 4 == 0 && s.length >= 16;
  }

  void _setStatut(String msg) {
    if (mounted) setState(() => _statutMessage = msg);
  }

  Future<void> _connecter() async {
    if (_appareilSelectionne == null) {
      _setStatut('⚠️ Veuillez sélectionner un appareil Bluetooth.');
      return;
    }
    try {
      await _bt.connecter(_appareilSelectionne!.address);
    } catch (e) {
      _setStatut('❌ Impossible de se connecter : $e');
    }
  }

  Future<void> _deconnecter() async {
    await _bt.deconnecter();
  }

  Future<void> _envoyerCommande(String cmd, String statutEnvoi) async {
    if (_bt.etat.value != EtatBluetooth.connecte) {
      _setStatut('⚠️ Non connecté. Connectez-vous d\'abord.');
      return;
    }
    try {
      _setStatut(statutEnvoi);
      await _bt.envoyerCommande(cmd);
    } catch (e) {
      _setStatut('❌ Erreur d\'envoi : $e');
    }
  }

  @override
  void dispose() {
    _abonnementMessages?.cancel();
    _bt.etat.removeListener(_onEtatChange);
    _bt.dispose();
    super.dispose();
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Interface utilisateur
  // ──────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final estConnecte = _bt.etat.value == EtatBluetooth.connecte;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Connectée'),
        centerTitle: true,
        actions: [
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
          IconButton(
            icon: const Icon(Icons.show_chart),
            tooltip: 'Courbe du poids',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CourbeScreen(),
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
            // ── Bloc connexion ──────────────────────────────────────────────
            _SectionCard(
              titre: 'Connexion Bluetooth',
              enfant: Column(
                children: [
                  DropdownButtonFormField<BluetoothDevice>(
                    decoration: const InputDecoration(
                      labelText: 'Appareil Bluetooth',
                      prefixIcon: Icon(Icons.bluetooth),
                      border: OutlineInputBorder(),
                    ),
                    value: _appareilSelectionne,
                    items: _appareils
                        .map(
                          (d) => DropdownMenuItem(
                            value: d,
                            child: Text(d.name ?? d.address),
                          ),
                        )
                        .toList(),
                    onChanged: estConnecte
                        ? null
                        : (d) => setState(() => _appareilSelectionne = d),
                    hint: _appareils.isEmpty
                        ? const Text('Aucun appareil appairé')
                        : const Text('Sélectionner un appareil'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: estConnecte || _chargement ? null : _connecter,
                          icon: _chargement
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.bluetooth_connected),
                          label: const Text('Connecter'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: estConnecte ? _deconnecter : null,
                          icon: const Icon(Icons.bluetooth_disabled),
                          label: const Text('Déconnecter'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        tooltip: 'Rafraîchir les appareils',
                        onPressed: _chargerAppareils,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ── Statut Arduino ──────────────────────────────────────────────
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: theme.colorScheme.secondary,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _statutMessage,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Affichage dernière mesure ───────────────────────────────────
            if (_derniereMesure != null)
              Card(
                color: theme.colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        'Dernière mesure',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_derniereMesure!.toStringAsFixed(3)} kg',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // ── Commandes balance ───────────────────────────────────────────
            _SectionCard(
              titre: 'Commandes',
              enfant: Column(
                children: [
                  _BoutonCommande(
                    libelle: 'Zéro (0 kg)',
                    icone: Icons.exposure_zero,
                    couleur: theme.colorScheme.tertiary,
                    actif: estConnecte,
                    onPressed: () => _envoyerCommande(
                      '0',
                      '📤 Envoi zéro kg à l\'Arduino…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BoutonCommande(
                    libelle: 'Tarer',
                    icone: Icons.balance,
                    couleur: theme.colorScheme.secondary,
                    actif: estConnecte,
                    onPressed: () => _envoyerCommande(
                      '1',
                      '📤 Demande de tarage envoyée…',
                    ),
                  ),
                  const SizedBox(height: 10),
                  _BoutonCommande(
                    libelle: 'Mesurer',
                    icone: Icons.monitor_weight,
                    couleur: theme.colorScheme.primary,
                    actif: estConnecte,
                    onPressed: () => _envoyerCommande(
                      '2',
                      '📤 Demande de mesure envoyée…',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets utilitaires
// ─────────────────────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String titre;
  final Widget enfant;

  const _SectionCard({required this.titre, required this.enfant});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titre,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            enfant,
          ],
        ),
      ),
    );
  }
}

class _BoutonCommande extends StatelessWidget {
  final String libelle;
  final IconData icone;
  final Color couleur;
  final bool actif;
  final VoidCallback onPressed;

  const _BoutonCommande({
    required this.libelle,
    required this.icone,
    required this.couleur,
    required this.actif,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        style: FilledButton.styleFrom(
          backgroundColor: actif ? couleur.withOpacity(0.15) : null,
          foregroundColor: actif ? couleur : null,
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: actif ? onPressed : null,
        icon: Icon(icone),
        label: Text(libelle, style: const TextStyle(fontSize: 16)),
      ),
    );
  }
}
