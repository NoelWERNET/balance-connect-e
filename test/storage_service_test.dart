import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:balance_connect_e/services/storage_service.dart';

void main() {
  setUpAll(() {
    // Initialise sqflite avec le driver FFI pour les tests unitaires hors device
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('StorageService', () {
    late StorageService storage;

    setUp(() async {
      storage = StorageService();
      await storage.init();
    });

    tearDown(() async {
      await storage.clearAll();
    });

    test('starts with no measurements', () {
      expect(storage.measurements, isEmpty);
    });

    test('addMeasurement stores a value', () async {
      await storage.addMeasurement(150.0);
      expect(storage.measurements.length, equals(1));
      expect(storage.measurements.first.value, equals(150.0));
    });

    test('measurements are ordered newest first', () async {
      await storage.addMeasurement(100.0);
      await Future.delayed(const Duration(milliseconds: 5));
      await storage.addMeasurement(200.0);

      expect(storage.measurements.first.value, equals(200.0));
      expect(storage.measurements.last.value, equals(100.0));
    });

    test('addMeasurement auto-deletes oldest when maxCount reached', () async {
      // Add 3 measurements with maxCount = 2
      await storage.addMeasurement(10.0, maxCount: 2);
      await storage.addMeasurement(20.0, maxCount: 2);
      await storage.addMeasurement(30.0, maxCount: 2);

      // Should keep only 2 most recent
      expect(storage.measurements.length, equals(2));
      // The oldest (10.0) should be gone
      expect(
          storage.measurements.any((m) => m.value == 10.0), isFalse);
      expect(
          storage.measurements.any((m) => m.value == 30.0), isTrue);
    });

    test('deleteOldest removes the oldest measurement', () async {
      await storage.addMeasurement(1.0);
      await Future.delayed(const Duration(milliseconds: 5));
      await storage.addMeasurement(2.0);
      await Future.delayed(const Duration(milliseconds: 5));
      await storage.addMeasurement(3.0);

      await storage.deleteOldest();

      expect(storage.measurements.length, equals(2));
      expect(storage.measurements.any((m) => m.value == 1.0), isFalse);
    });

    test('deleteById removes the correct measurement', () async {
      await storage.addMeasurement(42.0);
      final id = storage.measurements.first.id;
      expect(id, isNotNull);

      await storage.deleteById(id!);
      expect(storage.measurements, isEmpty);
    });

    test('clearAll removes everything', () async {
      await storage.addMeasurement(1.0);
      await storage.addMeasurement(2.0);
      await storage.clearAll();
      expect(storage.measurements, isEmpty);
    });
  });
}
