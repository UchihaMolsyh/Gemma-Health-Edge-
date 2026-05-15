class HealthSample {
  final String id;
  final String type; // e.g. 'HEART_RATE', 'BLOOD_OXYGEN'
  final double value;
  final String unit;
  final DateTime timestamp;
  final String source;

  const HealthSample({
    required this.id,
    required this.type,
    required this.value,
    required this.unit,
    required this.timestamp,
    required this.source,
  });

  bool get isValid => type.isNotEmpty;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'value': value,
      'unit': unit,
      'timestamp': timestamp.toIso8601String(),
      'source': source,
    };
  }

  factory HealthSample.fromJson(Map<String, dynamic> json) {
    final ts = json['timestamp'] as String?;
    return HealthSample(
      id: json['id'] as String? ?? '',
      type: json['type'] as String? ?? '',
      value: (json['value'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      timestamp: ts != null
          ? DateTime.tryParse(ts) ?? DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0),
      source: json['source'] as String? ?? '',
    );
  }
}
