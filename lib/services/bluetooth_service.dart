import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart'
    as fbs;

/// États possibles de la connexion Bluetooth.
enum BtConnectionState {
  disconnected,
  connecting,
  connected,
  error,
}

/// États du protocole de calibration / mesure.
///
/// Séquence :
///  [idle] → (envoi "0") → [zeroing] → (réponse Arduino) → [awaitingTare]
///  [awaitingTare] → (envoi "1") → [taring] → (réponse "PRET") → [ready]
///  [ready] → (envoi "2") → [measuring] → (réponse mesure chiffrée) → [ready]
enum ProtocolState {
  idle,
  zeroing,
  awaitingTare,
  taring,
  ready,
  measuring,
}

/// Gère la connexion Bluetooth Classic (SPP) avec la carte Arduino.
///
/// Les données reçues sont accumulées dans un tampon ligne par ligne ;
/// chaque ligne complète est émise sur [messageStream].
class BluetoothService extends ChangeNotifier {
  fbs.BluetoothConnection? _connection;
  BtConnectionState _connectionState = BtConnectionState.disconnected;
  ProtocolState _protocolState = ProtocolState.idle;
  String? _connectedDeviceName;
  String _buffer = '';

  final StreamController<String> _messageCtrl =
      StreamController<String>.broadcast();

  // ── Getters ───────────────────────────────────────────────────────────────

  BtConnectionState get connectionState => _connectionState;
  ProtocolState get protocolState => _protocolState;
  String? get connectedDeviceName => _connectedDeviceName;
  bool get isConnected => _connectionState == BtConnectionState.connected;

  /// Flux des lignes reçues depuis l'Arduino (sans le \n).
  Stream<String> get messageStream => _messageCtrl.stream;

  // ── Appareils ─────────────────────────────────────────────────────────────

  /// Retourne la liste des appareils Bluetooth déjà couplés.
  Future<List<fbs.BluetoothDevice>> getPairedDevices() async {
    return fbs.FlutterBluetoothSerial.instance.getBondedDevices();
  }

  // ── Connexion ─────────────────────────────────────────────────────────────

  Future<void> connect(fbs.BluetoothDevice device) async {
    _connectionState = BtConnectionState.connecting;
    _protocolState = ProtocolState.idle;
    notifyListeners();

    try {
      _connection =
          await fbs.BluetoothConnection.toAddress(device.address);
      _connectionState = BtConnectionState.connected;
      _connectedDeviceName = device.name ?? device.address;
      notifyListeners();

      _connection!.input!.listen(
        _onData,
        onDone: _onDisconnected,
        onError: (_) => _onDisconnected(),
        cancelOnError: true,
      );
    } catch (e) {
      _connectionState = BtConnectionState.error;
      _connectedDeviceName = null;
      notifyListeners();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    await _connection?.close();
    _onDisconnected();
  }

  // ── Commandes du protocole ────────────────────────────────────────────────

  /// Envoie la commande de remise à zéro (étape 1).
  Future<void> sendZero() async {
    _protocolState = ProtocolState.zeroing;
    notifyListeners();
    await _send('0');
  }

  /// Envoie la commande de tare (étape 2).
  Future<void> sendTare() async {
    _protocolState = ProtocolState.taring;
    notifyListeners();
    await _send('1');
  }

  /// Envoie la demande de mesure (étape 3).
  Future<void> sendMeasure() async {
    _protocolState = ProtocolState.measuring;
    notifyListeners();
    await _send('2');
  }

  /// Met à jour l'état du protocole (utilisé après traitement d'un message).
  void setProtocolState(ProtocolState state) {
    _protocolState = state;
    notifyListeners();
  }

  // ── Privé ─────────────────────────────────────────────────────────────────

  Future<void> _send(String command) async {
    if (_connection == null || !_connection!.isConnected) return;
    _connection!.output.add(Uint8List.fromList(utf8.encode('$command\n')));
    await _connection!.output.allSent;
  }

  void _onData(Uint8List data) {
    _buffer += utf8.decode(data, allowMalformed: true);
    while (_buffer.contains('\n')) {
      final idx = _buffer.indexOf('\n');
      final line = _buffer.substring(0, idx).trim();
      _buffer = _buffer.substring(idx + 1);
      if (line.isNotEmpty) {
        _messageCtrl.add(line);
      }
    }
  }

  void _onDisconnected() {
    _connectionState = BtConnectionState.disconnected;
    _connectedDeviceName = null;
    _connection = null;
    _buffer = '';
    _protocolState = ProtocolState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _connection?.close();
    _messageCtrl.close();
    super.dispose();
  }
}
