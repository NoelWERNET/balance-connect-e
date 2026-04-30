import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';

class CryptoService {
  // Clé AES partagée avec l'Arduino (16 caractères = 128 bits)
  static const String _cleAes = 'B7a6l5a4n3c2e1co';

  /// Déchiffre un message AES-ECB encodé en Base64
  String dechiffrer(String messageChiffre) {
    try {
      final cle = Key.fromUtf8(_cleAes);
      final encrypter = Encrypter(AES(cle, mode: AESMode.ecb, padding: 'PKCS7'));
      final encrypted = Encrypted.fromBase64(messageChiffre);
      return encrypter.decrypt(encrypted);
    } catch (e) {
      return messageChiffre;
    }
  }

  /// Chiffre un message avec AES-ECB encodé en Base64
  String chiffrer(String message) {
    try {
      final cle = Key.fromUtf8(_cleAes);
      final encrypter = Encrypter(AES(cle, mode: AESMode.ecb, padding: 'PKCS7'));
      return encrypter.encrypt(message).base64;
    } catch (e) {
      return message;
    }
  }

  /// Tente de déchiffrer un Uint8List reçu via Bluetooth
  String dechiffrerBytes(Uint8List bytes) {
    try {
      final raw = String.fromCharCodes(bytes).trim();
      return dechiffrer(raw);
    } catch (e) {
      return String.fromCharCodes(bytes).trim();
    }
  }
}
