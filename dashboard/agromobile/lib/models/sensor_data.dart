class SensorData {
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final double? lightLevel;
  final bool pumpStatus;
  final DateTime timestamp;

  SensorData({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.lightLevel,
    required this.pumpStatus,
    required this.timestamp,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed;
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final lower = value.toString().toLowerCase();
    return lower == 'on' || lower == 'true' || lower == '1';
  }

  factory SensorData.fromMap(Map<dynamic, dynamic> data) {
    final temperature = _toDouble(data['temperature'] ?? data['Temperature'] ?? data['temp'] ?? data['Temp']);
    final humidity = _toDouble(data['humidity'] ?? data['Humidity'] ?? data['Hum']);
    final soilMoisture = _toDouble(data['soilMoisture'] ?? data['SoilMoisture'] ?? data['soil'] ?? data['Soil']);
    final lightLevel = _toDouble(data['lightLevel'] ?? data['LightLevel'] ?? data['light'] ?? data['Light']);
    final pumpStatus = _toBool(data['pumpStatus'] ?? data['pump'] ?? data['PumpStatus'] ?? data['Irrigation'] ?? data['irrigation']);
    final tsRaw = data['timestamp'] ?? data['time'] ?? data['ts'];
    final tsMillis = tsRaw is num ? tsRaw.toInt() : int.tryParse(tsRaw?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;

    return SensorData(
      temperature: temperature,
      humidity: humidity,
      soilMoisture: soilMoisture,
      lightLevel: lightLevel,
      pumpStatus: pumpStatus,
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMillis),
    );
  }
}
