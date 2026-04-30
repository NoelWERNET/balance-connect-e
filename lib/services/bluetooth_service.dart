import 'dart:async';
import 'dart:typed_data';
import 'package:bluetooth_classic/bluetooth_classic.dart';
import 'package:bluetooth_classic/models/device.dart';
import 'package:flutter/foundation.dart';
import 'crypto_service.dart';

enum EtatBluetooth { deconnecte, connexionEnCours, connecte, erreur }

class BluetoothService {
  static const String _uuidSPP = '00001101-0000-1000-8000-00805f9b34fb';

  final BluetoothClassic _bluetooth = BluetoothClassic();
  final CryptoService _crypto = CryptoService();

  final ValueNotifier<EtatBluetooth> etat =
      ValueNotifier(EtatBluetooth.deconnecte);

  final StreamController<String> _messagesController =
      StreamController<String>.broadcast();
  Stream<String> get messages => _messagesController.stream;

  // Buffer pour reconstruire les messages entre délimiteurs * et #
  final StringBuffer _buffer = StringBuffer();

  StreamSubscription<Uint8List>? _donneesAbonnement;
  StreamSubscription<int>? _statutAbonnement;

  BluetoothService() {
    _ecouterStatut();
  }

  void _ecouterStatut() {
    _statutAbonnement = _bluetooth.onDeviceStatusChanged().listen((statut) {
      switch (statut) {
        case Device.connected:
          etat.value = EtatBluetooth.connecte;
          _ecouterDonnees();
        case Device.connecting:
          etat.value = EtatBluetooth.connexionEnCours;
        case Device.disconnected:
          etat.value = EtatBluetooth.deconnecte;
          _donneesAbonnement?.cancel();
          _donneesAbonnement = null;
          _buffer.clear();
        default:
          etat.value = EtatBluetooth.erreur;
          _donneesAbonnement?.cancel();
          _donneesAbonnement = null;
          _buffer.clear();
      }
    });
  }

  void _ecouterDonnees() {
    _donneesAbonnement?.cancel();
    _donneesAbonnement =
        _bluetooth.onDeviceDataReceived().listen((Uint8List octets) {
      final fragment = String.fromCharCodes(octets);
      _buffer.write(fragment);
      final contenu = _buffer.toString();

      // Les messages Arduino sont encadrés entre '*' et '#'
      int debut = contenu.indexOf('*');
      int fin = contenu.indexOf('#');

      while (debut != -1 && fin != -1 && fin > debut) {
        final messageBrut = contenu.substring(debut + 1, fin).trim();
        _traiterMessage(messageBrut);

        final reste = contenu.substring(fin + 1);
        _buffer.clear();
        _buffer.write(reste);

        final nouvContenu = _buffer.toString();
        debut = nouvContenu.indexOf('*');
        fin = nouvContenu.indexOf('#');
      }

      // Éviter que le buffer ne grossisse indéfiniment
      if (_buffer.length > 512) {
        _buffer.clear();
      }
    });
  }

  void _traiterMessage(String messageBrut) {
    String messageClair;
    if (messageBrut.startsWith('ENC')) {
      // Message chiffré : supprimer le préfixe ENC et déchiffrer
      final partieChiffree = messageBrut.substring(3).trim();
      messageClair = _crypto.dechiffrer(partieChiffree);
    } else {
      messageClair = messageBrut;
    }
    _messagesController.add(messageClair);
  }

  Future<void> demanderPermissions() async {
    await _bluetooth.initPermissions();
  }

  Future<List<Device>> appareilsAppaires() async {
    return _bluetooth.getPairedDevices();
  }

  Future<void> connecter(String adresse) async {
    try {
      etat.value = EtatBluetooth.connexionEnCours;
      await _bluetooth.connect(adresse, _uuidSPP);
    } catch (e) {
      etat.value = EtatBluetooth.erreur;
      rethrow;
    }
  }

  Future<void> deconnecter() async {
    await _bluetooth.disconnect();
    etat.value = EtatBluetooth.deconnecte;
    _buffer.clear();
  }

  Future<void> envoyerCommande(String commande) async {
    if (etat.value != EtatBluetooth.connecte) return;
    await _bluetooth.write(commande);
  }

  void dispose() {
    _donneesAbonnement?.cancel();
    _statutAbonnement?.cancel();
    _messagesController.close();
    etat.dispose();
  }
}
