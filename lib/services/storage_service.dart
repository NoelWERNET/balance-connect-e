import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mesure.dart';

/// Service de stockage local des mesures.
///
/// Conserve au maximum [maxMesures] entrées.
/// Quand la liste est pleine, la valeur la plus ancienne est supprimée
/// automatiquement avant d'ajouter la nouvelle.
class StorageService {
  static const int maxMesures = 50;
  static const String _cle = 'mesures';

  /// Charge la liste des mesures depuis le stockage local.
  Future<List<Mesure>> chargerMesures() async {
    final prefs = await SharedPreferences.getInstance();
    final donnees = prefs.getStringList(_cle) ?? [];
    return donnees
        .map((s) => Mesure.fromJsonString(s))
        .toList();
  }

  /// Sauvegarde une nouvelle [mesure].
  ///
  /// Si la liste contient déjà [maxMesures] éléments, la plus ancienne est
  /// retirée avant l'ajout.
  Future<List<Mesure>> ajouterMesure(Mesure mesure) async {
    final prefs = await SharedPreferences.getInstance();
    final mesures = await chargerMesures();

    if (mesures.length >= maxMesures) {
      mesures.removeAt(0);
    }
    mesures.add(mesure);

    await prefs.setStringList(
      _cle,
      mesures.map((m) => m.toJsonString()).toList(),
    );
    return mesures;
  }

  /// Supprime la mesure la plus ancienne de la liste.
  ///
  /// Ne fait rien si la liste est vide.
  Future<List<Mesure>> supprimerPlusVieille() async {
    final prefs = await SharedPreferences.getInstance();
    final mesures = await chargerMesures();

    if (mesures.isEmpty) return mesures;
    mesures.removeAt(0);

    await prefs.setStringList(
      _cle,
      mesures.map((m) => m.toJsonString()).toList(),
    );
    return mesures;
  }

  /// Efface toutes les mesures stockées.
  Future<void> viderMesures() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cle);
  }
}
