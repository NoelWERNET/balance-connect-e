import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/mesure.dart';

class StorageService {
  static const String _cleHistorique = 'historique_mesures';

  Future<List<Mesure>> chargerHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    final donnees = prefs.getStringList(_cleHistorique) ?? [];
    return donnees.map((s) {
      final json = jsonDecode(s) as Map<String, dynamic>;
      return Mesure.fromJson(json);
    }).toList();
  }

  Future<void> sauvegarderMesure(Mesure mesure) async {
    final prefs = await SharedPreferences.getInstance();
    final donnees = prefs.getStringList(_cleHistorique) ?? [];
    donnees.add(jsonEncode(mesure.toJson()));
    await prefs.setStringList(_cleHistorique, donnees);
  }

  Future<void> viderHistorique() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cleHistorique);
  }

  Future<void> sauvegarderListeMesures(List<Mesure> mesures) async {
    final prefs = await SharedPreferences.getInstance();
    final donnees = mesures.map((m) => jsonEncode(m.toJson())).toList();
    await prefs.setStringList(_cleHistorique, donnees);
  }
}
