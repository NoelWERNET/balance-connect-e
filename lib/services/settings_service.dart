import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/crypto_service.dart';

/// Service de gestion des paramètres de l'application.
///
/// Les paramètres sont persistés via [SharedPreferences].
class SettingsService extends ChangeNotifier {
  static const _keyAesKey = 'aes_key';
  static const _keyAesIv = 'aes_iv';
  static const _keyAesMode = 'aes_mode';
  static const _keyMaxMeasurements = 'max_measurements';

  String _aesKey = CryptoService.defaultKey;
  String _aesIv = CryptoService.defaultIv;
  AesMode _aesMode = AesMode.cbc;
  int _maxMeasurements = 100;

  String get aesKey => _aesKey;
  String get aesIv => _aesIv;
  AesMode get aesMode => _aesMode;
  int get maxMeasurements => _maxMeasurements;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _aesKey = prefs.getString(_keyAesKey) ?? CryptoService.defaultKey;
    _aesIv = prefs.getString(_keyAesIv) ?? CryptoService.defaultIv;
    _aesMode =
        prefs.getBool(_keyAesMode) == true ? AesMode.ecb : AesMode.cbc;
    _maxMeasurements = prefs.getInt(_keyMaxMeasurements) ?? 100;
    notifyListeners();
  }

  Future<void> saveAesKey(String key) async {
    _aesKey = key;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAesKey, key);
    notifyListeners();
  }

  Future<void> saveAesIv(String iv) async {
    _aesIv = iv;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAesIv, iv);
    notifyListeners();
  }

  Future<void> saveAesMode(AesMode mode) async {
    _aesMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyAesMode, mode == AesMode.ecb);
    notifyListeners();
  }

  Future<void> saveMaxMeasurements(int max) async {
    _maxMeasurements = max;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyMaxMeasurements, max);
    notifyListeners();
  }

  /// Crée un [CryptoService] avec les paramètres actuels.
  CryptoService buildCryptoService() => CryptoService(
        keyString: _aesKey,
        ivString: _aesIv,
        mode: _aesMode,
      );
}
