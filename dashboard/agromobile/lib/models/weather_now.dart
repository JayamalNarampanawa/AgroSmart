class WeatherNow {
  final String? description;
  final double temperature;
  final double humidity;
  final double windSpeed;
  final double rainfall;
  final DateTime? updatedAt;
  final String? source;

  WeatherNow({
    required this.description,
    required this.temperature,
    required this.humidity,
    required this.windSpeed,
    required this.rainfall,
    required this.updatedAt,
    required this.source,
  });

  factory WeatherNow.fromMap(Map<String, dynamic> map) {
    double _d(dynamic v) => v is num ? v.toDouble() : double.tryParse(v.toString()) ?? 0;
    DateTime? _ts(dynamic v) {
      if (v is num) return DateTime.fromMillisecondsSinceEpoch(v.toInt());
      final parsed = int.tryParse(v.toString());
      return parsed != null ? DateTime.fromMillisecondsSinceEpoch(parsed) : null;
    }

    return WeatherNow(
      description: map['description']?.toString(),
      temperature: _d(map['temperature']),
      humidity: _d(map['humidity']),
      windSpeed: _d(map['windSpeed']),
      rainfall: _d(map['rainfall']),
      updatedAt: _ts(map['updatedAt']),
      source: map['source']?.toString(),
    );
  }
}
