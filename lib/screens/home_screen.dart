import 'dart:async';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import '../services/bluetooth_service.dart';
import '../services/crypto_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';
import '../widgets/connection_status_card.dart';
import 'device_list_screen.dart';

/// Écran principal : connexion Bluetooth, calibration et prise de mesure.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  StreamSubscription<String>? _sub;
  String _lastArduinoMessage = '';
  String? _lastMeasurementDisplay;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _listenMessages();
    });
  }

  void _listenMessages() {
    final bt = context.read<BluetoothService>();
    _sub?.cancel();
    _sub = bt.messageStream.listen(_handleMessage);
  }

  /// Interprète les messages reçus de l'Arduino selon l'état du protocole.
  void _handleMessage(String message) {
    final bt = context.read<BluetoothService>();
    final upper = message.toUpperCase();

    setState(() => _lastArduinoMessage = message);

    switch (bt.protocolState) {
      case ProtocolState.zeroing:
        // L'Arduino demande de poser la masse de référence
        if (upper.contains('REFERENCE') ||
            upper.contains('REF') ||
            upper.contains('POSE') ||
            upper.contains('PLACER') ||
            upper.contains('TARE') ||
            upper.contains('MASSE')) {
          bt.setProtocolState(ProtocolState.awaitingTare);
          _showSnack('Posez la masse de référence puis appuyez sur Tarer');
        }
        break;

      case ProtocolState.taring:
        // L'Arduino confirme que la balance est prête
        if (upper.contains('PRET') ||
            upper.contains('READY') ||
            upper.contains('OK')) {
          bt.setProtocolState(ProtocolState.ready);
          _showSnack('Balance prête – vous pouvez mesurer');
        }
        break;

      case ProtocolState.measuring:
        // Réponse chiffrée : Base64(AES(valeur))
        _handleEncryptedMeasurement(message);
        break;

      default:
        break;
    }
  }

  void _handleEncryptedMeasurement(String encoded) {
    final bt = context.read<BluetoothService>();
    final settings = context.read<SettingsService>();
    final storage = context.read<StorageService>();

    try {
      final crypto = settings.buildCryptoService();
      final plain = crypto.decrypt(encoded).trim();
      final value = double.parse(plain);

      storage.addMeasurement(
        value,
        maxCount: settings.maxMeasurements,
      );

      setState(() {
        _lastMeasurementDisplay = _formatValue(value);
      });

      bt.setProtocolState(ProtocolState.ready);
    } catch (e) {
      _showSnack('Erreur de déchiffrement : $e');
      bt.setProtocolState(ProtocolState.ready);
    }
  }

  String _formatValue(double grams) {
    if (grams >= 1000) {
      return '${(grams / 1000).toStringAsFixed(3)} kg';
    }
    return '${grams.toStringAsFixed(1)} g';
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  // ── Gestion des permissions ───────────────────────────────────────────────

  Future<bool> _requestBluetoothPermissions() async {
    final statuses = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
    ].request();

    return statuses.values
        .every((s) => s.isGranted || s.isLimited);
  }

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _onConnectTap() async {
    final granted = await _requestBluetoothPermissions();
    if (!granted) {
      _showSnack('Permissions Bluetooth requises');
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const DeviceListScreen()),
    );
    _listenMessages();
  }

  Future<void> _onDisconnectTap() async {
    await context.read<BluetoothService>().disconnect();
    setState(() {
      _lastArduinoMessage = '';
      _lastMeasurementDisplay = null;
    });
  }

  Future<void> _onZeroTap() async {
    await context.read<BluetoothService>().sendZero();
    _showSnack('Remise à zéro envoyée…');
  }

  Future<void> _onTareTap() async {
    await context.read<BluetoothService>().sendTare();
    _showSnack('Tare en cours…');
  }

  Future<void> _onMeasureTap() async {
    await context.read<BluetoothService>().sendMeasure();
    _showSnack('Mesure en cours…');
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bt = context.watch<BluetoothService>();
    final connected = bt.isConnected;
    final proto = bt.protocolState;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Balance Connectée'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ── Connexion ──────────────────────────────────────────────────
            ConnectionStatusCard(
              state: bt.connectionState,
              deviceName: bt.connectedDeviceName,
              onConnect: _onConnectTap,
              onDisconnect: _onDisconnectTap,
            ),

            const SizedBox(height: 16),

            // ── Calibration ────────────────────────────────────────────────
            _SectionCard(
              title: 'Calibration',
              icon: Icons.tune,
              enabled: connected,
              children: [
                _StepRow(
                  step: '1',
                  label: 'Remise à zéro (0 kg)',
                  description:
                      'Retirez tout objet de la balance, puis appuyez.',
                  actionLabel: 'Mettre à zéro',
                  onAction: (proto == ProtocolState.idle) ? _onZeroTap : null,
                  loading: proto == ProtocolState.zeroing,
                  done: proto == ProtocolState.awaitingTare ||
                      proto == ProtocolState.taring ||
                      proto == ProtocolState.ready ||
                      proto == ProtocolState.measuring,
                ),
                const Divider(),
                _StepRow(
                  step: '2',
                  label: 'Tare',
                  description:
                      'Posez la masse de référence, puis appuyez.',
                  actionLabel: 'Tarer',
                  onAction: proto == ProtocolState.awaitingTare
                      ? _onTareTap
                      : null,
                  loading: proto == ProtocolState.taring,
                  done: proto == ProtocolState.ready ||
                      proto == ProtocolState.measuring,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ── Mesure ─────────────────────────────────────────────────────
            _SectionCard(
              title: 'Mesure',
              icon: Icons.monitor_weight,
              enabled: connected && proto == ProtocolState.ready,
              children: [
                if (_lastMeasurementDisplay != null) ...[
                  Text(
                    _lastMeasurementDisplay!,
                    style: Theme.of(context)
                        .textTheme
                        .displayMedium
                        ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (connected &&
                            proto == ProtocolState.ready)
                        ? _onMeasureTap
                        : null,
                    icon: proto == ProtocolState.measuring
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.straighten),
                    label: const Text('Prendre une mesure'),
                  ),
                ),
              ],
            ),

            // ── Dernier message Arduino ────────────────────────────────────
            if (_lastArduinoMessage.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.info_outline, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Arduino : $_lastArduinoMessage',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

// ── Composants internes ────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool enabled;
  final List<Widget> children;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20,
                    color: enabled
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: enabled ? null : Colors.grey,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final String step;
  final String label;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;
  final bool loading;
  final bool done;

  const _StepRow({
    required this.step,
    required this.label,
    required this.description,
    required this.actionLabel,
    this.onAction,
    this.loading = false,
    this.done = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: done
              ? Colors.green
              : loading
                  ? Colors.orange
                  : Theme.of(context).colorScheme.secondaryContainer,
          child: done
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : loading
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(step,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text(description,
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        const SizedBox(width: 8),
        OutlinedButton(
          onPressed: onAction,
          child: Text(actionLabel),
        ),
      ],
    );
  }
}
