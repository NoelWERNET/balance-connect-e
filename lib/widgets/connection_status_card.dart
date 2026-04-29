import 'package:flutter/material.dart';
import '../services/bluetooth_service.dart';

/// Carte affichant l'état de la connexion Bluetooth.
class ConnectionStatusCard extends StatelessWidget {
  final BtConnectionState state;
  final String? deviceName;
  final VoidCallback onConnect;
  final VoidCallback onDisconnect;

  const ConnectionStatusCard({
    super.key,
    required this.state,
    this.deviceName,
    required this.onConnect,
    required this.onDisconnect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _StatusIndicator(state: state),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  if (deviceName != null)
                    Text(
                      deviceName!,
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            if (state == BtConnectionState.connected)
              OutlinedButton.icon(
                onPressed: onDisconnect,
                icon: const Icon(Icons.bluetooth_disabled),
                label: const Text('Déconnecter'),
              )
            else
              FilledButton.icon(
                onPressed: state == BtConnectionState.connecting
                    ? null
                    : onConnect,
                icon: const Icon(Icons.bluetooth),
                label: const Text('Connecter'),
              ),
          ],
        ),
      ),
    );
  }

  String get _label {
    switch (state) {
      case BtConnectionState.connected:
        return 'Connecté';
      case BtConnectionState.connecting:
        return 'Connexion en cours…';
      case BtConnectionState.error:
        return 'Erreur de connexion';
      case BtConnectionState.disconnected:
        return 'Déconnecté';
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final BtConnectionState state;
  const _StatusIndicator({required this.state});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (state) {
      case BtConnectionState.connected:
        color = Colors.green;
        break;
      case BtConnectionState.connecting:
        color = Colors.orange;
        break;
      case BtConnectionState.error:
        color = Colors.red;
        break;
      case BtConnectionState.disconnected:
        color = Colors.grey;
        break;
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
