import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as fbs;
import 'package:provider/provider.dart';
import '../services/bluetooth_service.dart';

/// Écran de sélection d'un appareil Bluetooth couplé.
class DeviceListScreen extends StatefulWidget {
  const DeviceListScreen({super.key});

  @override
  State<DeviceListScreen> createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  List<fbs.BluetoothDevice>? _devices;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bt = context.read<BluetoothService>();
      final devices = await bt.getPairedDevices();
      if (mounted) setState(() => _devices = devices);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Appareils couplés'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() => _devices = null);
              _load();
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 8),
            Text('Erreur : $_error'),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Réessayer')),
          ],
        ),
      );
    }

    if (_devices == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_devices!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.bluetooth_disabled, size: 48),
            const SizedBox(height: 8),
            const Text(
                'Aucun appareil couplé.\nCouplez votre module HC-05/HC-06\ndans les paramètres Bluetooth Android.',
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton(onPressed: _load, child: const Text('Actualiser')),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _devices!.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, i) {
        final d = _devices![i];
        return ListTile(
          leading: const Icon(Icons.bluetooth),
          title: Text(d.name ?? 'Appareil inconnu'),
          subtitle: Text(d.address),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _connect(d),
        );
      },
    );
  }

  Future<void> _connect(fbs.BluetoothDevice device) async {
    final bt = context.read<BluetoothService>();
    try {
      await bt.connect(device);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Connexion impossible : $e')),
        );
      }
    }
  }
}
