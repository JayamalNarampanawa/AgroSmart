class SensorHistory {
  final String id;
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightLevel;
  final bool pumpStatus;
  final DateTime timestamp;

  const SensorHistory({
    required this.id,
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    required this.pumpStatus,
    required this.timestamp,
  });

  double soilWetnessPercent({int wetMin = 1200, int dryMax = 4095}) {
    final clamped = soilMoisture.clamp(wetMin.toDouble(), dryMax.toDouble());
    return ((dryMax - clamped) / (dryMax - wetMin) * 100).clamp(0.0, 100.0);
  }

  factory SensorHistory.fromMap(String id, Map<Object?, Object?> data) {
    double? toD(Object? v) {
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    return SensorHistory(
      id: id,
      temperature: toD(data['temperature']) ?? 0.0,
      humidity: toD(data['humidity']) ?? 0.0,
      soilMoisture: toD(data['soilMoisture']) ?? 2048.0,
      lightLevel: toD(data['lightLevel']) ?? 0.0,
      pumpStatus: data['pumpStatus'] == true || data['pumpStatus'] == 1,
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (toD(data['timestamp'])!).toInt(),
            )
          : DateTime.now(),
    );
  }
}
