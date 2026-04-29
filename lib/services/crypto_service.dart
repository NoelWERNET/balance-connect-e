import 'dart:convert';
import 'package:encrypt/encrypt.dart' as enc;

/// Service de déchiffrement AES + Base64.
///
/// La clé partagée avec l'Arduino est [_cleAes] (16 octets, mode ECB).
class CryptoService {
  static const String _cleAes = '1234567890123456';

  /// Déchiffre un message encodé en AES-ECB puis en Base64.
  ///
  /// Retourne la valeur en kg sous forme de [double],
  /// ou lève une [FormatException] si le déchiffrement échoue.
  double decrypterMesure(String messageBase64) {
    final key = enc.Key.fromUtf8(_cleAes);
    final encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.ecb));

    final encrypted = enc.Encrypted(base64Decode(messageBase64));
    final decrypted = encrypter.decrypt(encrypted);

    final valeur = double.tryParse(decrypted.trim());
    if (valeur == null) {
      throw FormatException(
        'Impossible de convertir le message déchiffré en nombre : "$decrypted"',
      );
    }
    return valeur;
  }
}
