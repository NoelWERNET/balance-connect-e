import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;

/// Service de chiffrement / déchiffrement AES utilisé pour communiquer
/// avec l'Arduino.
///
/// L'Arduino chiffre la mesure en AES puis l'encode en Base64.
/// Cette classe effectue le chemin inverse : Base64 → AES decrypt → valeur.
class CryptoService {
  /// Clé AES par défaut (16 octets = AES-128).
  /// **Doit** correspondre à la clé programmée sur l'Arduino.
  static const String defaultKey = 'BalanceSecretKey';

  /// Vecteur d'initialisation par défaut (CBC uniquement, 16 octets).
  static const String defaultIv = 'InitVector123456';

  final String keyString;
  final String ivString;
  final AesMode mode;

  CryptoService({
    this.keyString = defaultKey,
    this.ivString = defaultIv,
    this.mode = AesMode.cbc,
  });

  /// Décrypte une chaîne Base64 reçue de l'Arduino.
  ///
  /// Retourne la valeur en clair (ex. "123.45").
  /// Lance une [Exception] si le déchiffrement échoue.
  String decrypt(String base64Encoded) {
    final rawKey = _buildKey(keyString);
    final key = enc.Key(rawKey);

    try {
      if (mode == AesMode.ecb) {
        return _decryptEcb(base64Encoded, key);
      } else {
        return _decryptCbc(base64Encoded, key);
      }
    } catch (_) {
      // Fallback : essaie l'autre mode si le premier échoue
      try {
        if (mode == AesMode.ecb) {
          return _decryptCbc(base64Encoded, key);
        } else {
          return _decryptEcb(base64Encoded, key);
        }
      } catch (e) {
        throw Exception('Échec du déchiffrement AES : $e');
      }
    }
  }

  /// Chiffre une chaîne en AES puis l'encode en Base64 (utile pour les tests).
  String encrypt(String plaintext) {
    final rawKey = _buildKey(keyString);
    final key = enc.Key(rawKey);

    if (mode == AesMode.ecb) {
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
      return encrypter.encrypt(plaintext, iv: enc.IV(Uint8List(16))).base64;
    } else {
      final iv = enc.IV(_buildKey(ivString));
      final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
      return encrypter.encrypt(plaintext, iv: iv).base64;
    }
  }

  // ── privé ─────────────────────────────────────────────────────────────────

  String _decryptCbc(String base64Encoded, enc.Key key) {
    final iv = enc.IV(_buildKey(ivString));
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    final encrypted = enc.Encrypted.fromBase64(base64Encoded);
    return encrypter.decrypt(encrypted, iv: iv).trim();
  }

  String _decryptEcb(String base64Encoded, enc.Key key) {
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));
    final encrypted = enc.Encrypted.fromBase64(base64Encoded);
    return encrypter.decrypt(encrypted, iv: enc.IV(Uint8List(16))).trim();
  }

  /// Construit une clé de 16 octets à partir d'une chaîne UTF-8.
  Uint8List _buildKey(String source) {
    final bytes = utf8.encode(source);
    final result = Uint8List(16);
    for (int i = 0; i < 16; i++) {
      result[i] = i < bytes.length ? bytes[i] : 0;
    }
    return result;
  }
}

/// Mode AES utilisé pour le chiffrement / déchiffrement.
enum AesMode { cbc, ecb }
