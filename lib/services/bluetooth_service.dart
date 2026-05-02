import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// États possibles de la connexion Bluetooth.
enum EtatBluetooth {
  deconnecte,
  connexionEnCours,
  connecte,
  erreur,
}

/// Service de communication Bluetooth avec l'Arduino.
class BluetoothService {
  /// UUID du profil SPP (Serial Port Profile) Bluetooth Classic.
  static const String _sppUuid = '00001101-0000-1000-8000-00805f9b34fb';

  final _plugin = BluetoothClassic();
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final ValueNotifier<EtatBluetooth> etat =
      ValueNotifier(EtatBluetooth.deconnecte);

  StreamSubscription? _statusSub;
  StreamSubscription? _dataSub;
  String _tampon = '';

  Stream<String> get messages => _messageController.stream;

  Future<bool> demanderPermissions() async {
    final statuts = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();
    return statuts.values.every((s) => s == PermissionStatus.granted);
  }

  Future<List<Device>> appareilsAppaires() async {
    return _plugin.getPairedDevices();
  }

  Future<void> connecter(String adresse) async {
    if (etat.value == EtatBluetooth.connexionEnCours ||
        etat.value == EtatBluetooth.connecte) return;

    etat.value = EtatBluetooth.connexionEnCours;
    try {
      _statusSub = _plugin.onDeviceStatusChanged().listen((status) {
        if (status == Device.disconnected) _onDeconnexion();
      });
      _dataSub = _plugin.onDeviceDataReceived().listen(_onData);
      await _plugin.connect(adresse, _sppUuid);
      etat.value = EtatBluetooth.connecte;
    } catch (e) {
      etat.value = EtatBluetooth.erreur;
      debugPrint('Erreur de connexion Bluetooth : $e');
      rethrow;
    }
  }

  Future<void> deconnecter() async {
    await _plugin.disconnect();
    _statusSub?.cancel();
    _dataSub?.cancel();
    _tampon = '';
    etat.value = EtatBluetooth.deconnecte;
  }

  Future<void> envoyerCommande(String commande) async {
    if (etat.value != EtatBluetooth.connecte) {
      throw StateError('Non connecté à un appareil Bluetooth.');
    }
    await _plugin.write(commande);
  }

  void _onData(Uint8List donnees) {
    _tampon += utf8.decode(donnees);
    final lignes = _tampon.split('\n');
    _tampon = lignes.removeLast();
    for (final ligne in lignes) {
      final msg = ligne.trim();
      if (msg.isNotEmpty) _messageController.add(msg);
    }
  }

  void _onDeconnexion() {
    _tampon = '';
    etat.value = EtatBluetooth.deconnecte;
  }

  void dispose() {
    deconnecter();
    _messageController.close();
    etat.dispose();
  }
}
