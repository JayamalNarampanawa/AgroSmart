class AnalyticsPoint {
  final double? temperature;
  final double? humidity;
  final double? soilMoisture;
  final bool pumpStatus;
  final DateTime timestamp;
  final String source;

  AnalyticsPoint({
    required this.temperature,
    required this.humidity,
    required this.soilMoisture,
    required this.pumpStatus,
    required this.timestamp,
    required this.source,
  });

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  static bool _toBool(dynamic value) {
    if (value == null) return false;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final lower = value.toString().toLowerCase();
    return lower == 'true' || lower == '1' || lower == 'on';
  }

  factory AnalyticsPoint.fromMap(Map<dynamic, dynamic> data) {
    final tsRaw = data['timestamp'];
    final tsMillis = tsRaw is num ? tsRaw.toInt() : int.tryParse(tsRaw?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch;
    return AnalyticsPoint(
      temperature: _toDouble(data['temperature']),
      humidity: _toDouble(data['humidity']),
      soilMoisture: _toDouble(data['soilMoisture']),
      pumpStatus: _toBool(data['pumpStatus']),
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMillis),
      source: data['source']?.toString() ?? 'sensor',
    );
  }
}
