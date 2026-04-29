import 'package:flutter_test/flutter_test.dart';
import 'package:balance_connect_e/services/crypto_service.dart';

void main() {
  group('CryptoService', () {
    late CryptoService crypto;

    setUp(() {
      crypto = CryptoService(
        keyString: 'BalanceSecretKey',
        ivString: 'InitVector123456',
        mode: AesMode.cbc,
      );
    });

    test('encrypt then decrypt returns original value (CBC)', () {
      const original = '123.45';
      final encrypted = crypto.encrypt(original);
      expect(encrypted, isNotEmpty);
      final decrypted = crypto.decrypt(encrypted);
      expect(decrypted, equals(original));
    });

    test('encrypt then decrypt returns original value (ECB)', () {
      final ecbCrypto = CryptoService(
        keyString: 'BalanceSecretKey',
        ivString: 'InitVector123456',
        mode: AesMode.ecb,
      );
      const original = '456.78';
      final encrypted = ecbCrypto.encrypt(original);
      final decrypted = ecbCrypto.decrypt(encrypted);
      expect(decrypted, equals(original));
    });

    test('key is padded to 16 bytes when shorter', () {
      final shortKeyCrypto = CryptoService(
        keyString: 'Short',
        ivString: 'IV',
        mode: AesMode.cbc,
      );
      const original = '999.00';
      final encrypted = shortKeyCrypto.encrypt(original);
      final decrypted = shortKeyCrypto.decrypt(encrypted);
      expect(decrypted, equals(original));
    });

    test('decrypt with wrong key throws Exception', () {
      const original = '100.00';
      final encrypted = crypto.encrypt(original);

      final wrongKeyCrypto = CryptoService(
        keyString: 'WrongKey1234XXXX',
        ivString: 'InitVector123456',
        mode: AesMode.cbc,
      );

      expect(
        () => wrongKeyCrypto.decrypt(encrypted),
        throwsA(isA<Exception>()),
      );
    });

    test('decrypted value can be parsed as double', () {
      const value = 512.75;
      final encoded = crypto.encrypt(value.toString());
      final decoded = double.parse(crypto.decrypt(encoded));
      expect(decoded, closeTo(value, 0.001));
    });
  });
}
