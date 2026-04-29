import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/crypto_service.dart';
import '../services/settings_service.dart';

/// Écran de configuration de l'application.
///
/// Permet de régler la clé AES, le vecteur d'initialisation,
/// le mode AES (CBC / ECB) et le nombre maximum de mesures conservées.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _keyCtrl;
  late TextEditingController _ivCtrl;
  late TextEditingController _maxCtrl;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    final s = context.read<SettingsService>();
    _keyCtrl = TextEditingController(text: s.aesKey);
    _ivCtrl = TextEditingController(text: s.aesIv);
    _maxCtrl = TextEditingController(text: s.maxMeasurements.toString());
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _ivCtrl.dispose();
    _maxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final s = context.read<SettingsService>();

    // Validation clé AES
    final key = _keyCtrl.text.trim();
    if (key.length < 8) {
      _showError('La clé AES doit contenir au moins 8 caractères.');
      return;
    }

    // Validation IV
    final iv = _ivCtrl.text.trim();
    if (iv.isNotEmpty && iv.length < 8) {
      _showError('Le vecteur d\'initialisation doit contenir au moins 8 caractères.');
      return;
    }

    // Validation max mesures
    final max = int.tryParse(_maxCtrl.text.trim());
    if (max == null || max < 1 || max > 10000) {
      _showError('Le nombre max de mesures doit être entre 1 et 10 000.');
      return;
    }

    await s.saveAesKey(key);
    if (iv.isNotEmpty) await s.saveAesIv(iv);
    await s.saveMaxMeasurements(max);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Paramètres enregistrés')),
      );
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Paramètres'),
        actions: [
          TextButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Section AES ───────────────────────────────────────────────────
          _SectionHeader(title: 'Chiffrement AES'),
          const SizedBox(height: 8),

          TextFormField(
            controller: _keyCtrl,
            obscureText: _obscureKey,
            decoration: InputDecoration(
              labelText: 'Clé AES (16 caractères recommandés)',
              hintText: CryptoService.defaultKey,
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(
                    _obscureKey ? Icons.visibility : Icons.visibility_off),
                onPressed: () =>
                    setState(() => _obscureKey = !_obscureKey),
              ),
            ),
          ),

          const SizedBox(height: 12),

          TextFormField(
            controller: _ivCtrl,
            decoration: const InputDecoration(
              labelText: 'Vecteur d\'initialisation IV (CBC uniquement)',
              hintText: CryptoService.defaultIv,
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 12),

          // Mode AES
          Card(
            child: Column(
              children: [
                RadioListTile<AesMode>(
                  title: const Text('CBC (recommandé)'),
                  subtitle: const Text('Cipher Block Chaining'),
                  value: AesMode.cbc,
                  groupValue: settings.aesMode,
                  onChanged: (v) => settings.saveAesMode(v!),
                ),
                RadioListTile<AesMode>(
                  title: const Text('ECB'),
                  subtitle: const Text('Electronic Codebook – certains modules Arduino'),
                  value: AesMode.ecb,
                  groupValue: settings.aesMode,
                  onChanged: (v) => settings.saveAesMode(v!),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section stockage ──────────────────────────────────────────────
          _SectionHeader(title: 'Stockage'),
          const SizedBox(height: 8),

          TextFormField(
            controller: _maxCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Nombre maximum de mesures conservées',
              hintText: '100',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Quand cette limite est atteinte, la mesure la plus ancienne\n'
            'est automatiquement supprimée à chaque nouvelle mesure.',
            style: Theme.of(context).textTheme.bodySmall,
          ),

          const SizedBox(height: 32),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text('Enregistrer les paramètres'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}
