import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import '../models/measurement.dart';

/// Service de persistance des mesures dans une base SQLite locale.
///
/// • Les mesures sont triées par date décroissante (la plus récente en tête).
/// • Quand le nombre maximum est atteint, la **plus ancienne** mesure est
///   supprimée automatiquement avant d'insérer la nouvelle.
/// • L'utilisateur peut aussi supprimer manuellement la plus ancienne.
class StorageService extends ChangeNotifier {
  static const _dbName = 'balance.db';
  static const _tableName = 'measurements';
  static const int defaultMaxCount = 100;

  Database? _db;
  List<Measurement> _measurements = [];

  List<Measurement> get measurements => List.unmodifiable(_measurements);

  // ── Initialisation ────────────────────────────────────────────────────────

  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: 1,
      onCreate: _onCreate,
    );
    await _reload();
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_tableName (
        id        INTEGER PRIMARY KEY AUTOINCREMENT,
        value     REAL    NOT NULL,
        timestamp INTEGER NOT NULL
      )
    ''');
  }

  // ── Opérations publiques ──────────────────────────────────────────────────

  /// Ajoute une mesure.
  ///
  /// Si le nombre de mesures enregistrées atteint [maxCount], la plus
  /// ancienne est **supprimée** avant l'insertion (comportement "rolling").
  Future<void> addMeasurement(
    double value, {
    int maxCount = defaultMaxCount,
  }) async {
    assert(_db != null, 'StorageService non initialisé');
    if (_measurements.length >= maxCount) {
      await _deleteOldest();
    }
    await _db!.insert(_tableName, {
      'value': value,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await _reload();
  }

  /// Supprime explicitement la mesure la plus ancienne.
  Future<void> deleteOldest() async {
    assert(_db != null, 'StorageService non initialisé');
    await _deleteOldest();
    await _reload();
  }

  /// Supprime une mesure par son identifiant.
  Future<void> deleteById(int id) async {
    assert(_db != null, 'StorageService non initialisé');
    await _db!.delete(_tableName, where: 'id = ?', whereArgs: [id]);
    await _reload();
  }

  /// Supprime toutes les mesures.
  Future<void> clearAll() async {
    assert(_db != null, 'StorageService non initialisé');
    await _db!.delete(_tableName);
    _measurements = [];
    notifyListeners();
  }

  // ── Privé ─────────────────────────────────────────────────────────────────

  Future<void> _deleteOldest() async {
    if (_measurements.isEmpty) return;
    // La liste est triée par date décroissante → le dernier est le plus ancien
    final oldest = _measurements.last;
    if (oldest.id != null) {
      await _db!
          .delete(_tableName, where: 'id = ?', whereArgs: [oldest.id]);
    }
  }

  Future<void> _reload() async {
    final rows = await _db!.query(
      _tableName,
      orderBy: 'timestamp DESC',
    );
    _measurements = rows.map(Measurement.fromMap).toList();
    notifyListeners();
  }
}
