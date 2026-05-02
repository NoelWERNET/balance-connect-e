import 'dart:convert';

class Mesure {
  final double valeur;
  final DateTime horodatage;

  const Mesure({
    required this.valeur,
    required this.horodatage,
  });

  Map<String, dynamic> toJson() => {
        'valeur': valeur,
        'horodatage': horodatage.toIso8601String(),
      };

  factory Mesure.fromJson(Map<String, dynamic> json) => Mesure(
        valeur: (json['valeur'] as num).toDouble(),
        horodatage: DateTime.parse(json['horodatage'] as String),
      );

  String toJsonString() => jsonEncode(toJson());

  factory Mesure.fromJsonString(String source) =>
      Mesure.fromJson(jsonDecode(source) as Map<String, dynamic>);

  @override
  String toString() =>
      'Mesure(valeur: $valeur kg, horodatage: $horodatage)';
}
