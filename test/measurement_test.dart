import 'package:flutter_test/flutter_test.dart';
import 'package:balance_connect_e/models/measurement.dart';

void main() {
  group('Measurement model', () {
    test('toMap / fromMap round-trip', () {
      final original = Measurement(
        id: 1,
        value: 250.5,
        timestamp: DateTime(2025, 6, 15, 10, 30, 0),
      );
      final map = original.toMap();
      final restored = Measurement.fromMap(map);

      expect(restored.id, equals(original.id));
      expect(restored.value, equals(original.value));
      expect(restored.timestamp.millisecondsSinceEpoch,
          equals(original.timestamp.millisecondsSinceEpoch));
    });

    test('copyWith preserves unchanged fields', () {
      final m = Measurement(
        id: 5,
        value: 100.0,
        timestamp: DateTime(2025, 1, 1),
      );
      final copy = m.copyWith(value: 200.0);
      expect(copy.id, equals(m.id));
      expect(copy.value, equals(200.0));
      expect(copy.timestamp, equals(m.timestamp));
    });

    test('toMap does not include null id', () {
      final m = Measurement(
        value: 300.0,
        timestamp: DateTime.now(),
      );
      expect(m.toMap().containsKey('id'), isFalse);
    });
  });
}
