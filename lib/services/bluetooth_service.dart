import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';

/// États possibles de la connexion Bluetooth.
enum EtatBluetooth {
  deconnecte,
  connexionEnCours,
  connecte,
  erreur,
}

/// Service de communication Bluetooth avec l'Arduino.
///
/// Expose un [StreamController] pour les messages reçus et un
/// [ValueNotifier] pour l'état de la connexion.
class BluetoothService {
  BluetoothConnection? _connexion;
  final StreamController<String> _messageController =
      StreamController<String>.broadcast();
  final ValueNotifier<EtatBluetooth> etat =
      ValueNotifier(EtatBluetooth.deconnecte);

  String _tampon = '';

  /// Flux des messages texte reçus depuis l'Arduino.
  Stream<String> get messages => _messageController.stream;

  /// Demande les permissions Bluetooth nécessaires (Android 12+).
  Future<bool> demanderPermissions() async {
    final statuts = await [
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
    ].request();

    return statuts.values.every(
      (s) => s == PermissionStatus.granted,
    );
  }

  /// Retourne la liste des appareils Bluetooth appairés.
  Future<List<BluetoothDevice>> appareilsAppaires() async {
    return FlutterBluetoothSerial.instance.getBondedDevices();
  }

  /// Établit une connexion avec l'appareil [adresse].
  Future<void> connecter(String adresse) async {
    if (etat.value == EtatBluetooth.connexionEnCours ||
        etat.value == EtatBluetooth.connecte) {
      return;
    }

    etat.value = EtatBluetooth.connexionEnCours;
    try {
      _connexion = await BluetoothConnection.toAddress(adresse);
      etat.value = EtatBluetooth.connecte;

      _connexion!.input!.listen(
        _onData,
        onDone: _onDeconnexion,
        onError: (_) => _onDeconnexion(),
        cancelOnError: true,
      );
    } catch (e) {
      etat.value = EtatBluetooth.erreur;
      debugPrint('Erreur de connexion Bluetooth : $e');
      rethrow;
    }
  }

  /// Ferme la connexion Bluetooth.
  Future<void> deconnecter() async {
    await _connexion?.close();
    _connexion = null;
    _tampon = '';
    etat.value = EtatBluetooth.deconnecte;
  }

  /// Envoie une commande (un caractère) vers l'Arduino.
  Future<void> envoyerCommande(String commande) async {
    if (_connexion == null || etat.value != EtatBluetooth.connecte) {
      throw StateError('Non connecté à un appareil Bluetooth.');
    }
    _connexion!.output.add(Uint8List.fromList(utf8.encode(commande)));
    await _connexion!.output.allSent;
  }

  void _onData(Uint8List donnees) {
    _tampon += utf8.decode(donnees);
    // Découpe sur les sauts de ligne pour obtenir des messages complets.
    final lignes = _tampon.split('\n');
    // La dernière partie peut être incomplète — on la remet en tampon.
    _tampon = lignes.removeLast();
    for (final ligne in lignes) {
      final msg = ligne.trim();
      if (msg.isNotEmpty) {
        _messageController.add(msg);
      }
    }
  }

  void _onDeconnexion() {
    _connexion = null;
    _tampon = '';
    etat.value = EtatBluetooth.deconnecte;
  }

  /// Libère les ressources du service.
  void dispose() {
    deconnecter();
    _messageController.close();
    etat.dispose();
  }
}
