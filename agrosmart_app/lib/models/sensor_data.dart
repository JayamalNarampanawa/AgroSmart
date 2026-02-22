class SensorData {
  final double temperature;
  final double humidity;
  final double soilMoisture;
  final double lightLevel;
  final bool pumpStatus;
  final DateTime timestamp;

  const SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    required this.pumpStatus,
    required this.timestamp,
  });

  // Raw soil moisture → wetness % (0 = dry, 100 = wet)
  // Default calibration: wetMin=1200, dryMax=4095
  double soilWetnessPercent({int wetMin = 1200, int dryMax = 4095}) {
    final clamped = soilMoisture.clamp(wetMin.toDouble(), dryMax.toDouble());
    final pct = ((dryMax - clamped) / (dryMax - wetMin)) * 100;
    return pct.clamp(0.0, 100.0);
  }

  String get soilStatus {
    final w = soilWetnessPercent();
    if (w < 30) return 'Dry';
    if (w > 75) return 'Wet';
    return 'Optimal';
  }

  String get irrigationAdvice => soilWetnessPercent() < 40 ? 'ON' : 'OFF';

  bool get hasHeatRisk => temperature > 35;
  bool get hasLowLight => lightLevel < 500;

  factory SensorData.fromMap(Map<Object?, Object?> data) {
    return SensorData(
      temperature: _toDouble(data['temperature']) ?? 0.0,
      humidity: _toDouble(data['humidity']) ?? 0.0,
      soilMoisture: _toDouble(data['soilMoisture']) ?? 2048.0,
      lightLevel: _toDouble(data['lightLevel']) ?? 0.0,
      pumpStatus: data['pumpStatus'] == true || data['pumpStatus'] == 1,
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              _toDouble(data['timestamp'])!.toInt(),
            )
          : DateTime.now(),
    );
  }

  static double? _toDouble(Object? val) {
    if (val == null) return null;
    if (val is double) return val;
    if (val is int) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }

  SensorData copyWith({
    double? temperature,
    double? humidity,
    double? soilMoisture,
    double? lightLevel,
    bool? pumpStatus,
    DateTime? timestamp,
  }) =>
      SensorData(
        temperature: temperature ?? this.temperature,
        humidity: humidity ?? this.humidity,
        soilMoisture: soilMoisture ?? this.soilMoisture,
        lightLevel: lightLevel ?? this.lightLevel,
        pumpStatus: pumpStatus ?? this.pumpStatus,
        timestamp: timestamp ?? this.timestamp,
      );

  @override
  String toString() =>
      'SensorData(temp=$temperature, hum=$humidity, soil=$soilMoisture,'
      ' light=$lightLevel, pump=$pumpStatus, ts=$timestamp)';
}
