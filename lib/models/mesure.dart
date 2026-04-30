class Mesure {
  final double poids;
  final DateTime dateHeure;

  Mesure({required this.poids, required this.dateHeure});

  Map<String, dynamic> toJson() => {
        'poids': poids,
        'dateHeure': dateHeure.toIso8601String(),
      };

  factory Mesure.fromJson(Map<String, dynamic> json) => Mesure(
        poids: (json['poids'] as num).toDouble(),
        dateHeure: DateTime.parse(json['dateHeure'] as String),
      );

  @override
  String toString() => 'Mesure(poids: $poids, dateHeure: $dateHeure)';
}
