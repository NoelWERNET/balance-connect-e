/// Représente une mesure de poids enregistrée par la balance.
class Measurement {
  final int? id;

  /// Valeur en grammes.
  final double value;

  final DateTime timestamp;

  const Measurement({
    this.id,
    required this.value,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'value': value,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };

  factory Measurement.fromMap(Map<String, dynamic> map) => Measurement(
        id: map['id'] as int?,
        value: (map['value'] as num).toDouble(),
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );

  Measurement copyWith({int? id, double? value, DateTime? timestamp}) =>
      Measurement(
        id: id ?? this.id,
        value: value ?? this.value,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  String toString() =>
      'Measurement(id: $id, value: $value g, timestamp: $timestamp)';
}
