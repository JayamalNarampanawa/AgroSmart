class AIInsight {
  final String soilStatus;
  final String irrigationAdvice;
  final bool heatRisk;
  final bool lowLight;
  final bool sensorStale;
  final String summary;
  final DateTime timestamp;

  const AIInsight({
    this.soilStatus = 'Unknown',
    this.irrigationAdvice = 'OFF',
    this.heatRisk = false,
    this.lowLight = false,
    this.sensorStale = false,
    this.summary = '',
    required this.timestamp,
  });

  factory AIInsight.fromMap(Map<Object?, Object?> data) {
    final flags = data['riskFlags'] as Map<Object?, Object?>? ?? {};
    return AIInsight(
      soilStatus: data['soilStatus']?.toString() ?? 'Unknown',
      irrigationAdvice: data['irrigationAdvice']?.toString() ?? 'OFF',
      heatRisk: flags['heatRisk'] == true,
      lowLight: flags['lowLight'] == true,
      sensorStale: flags['sensorStale'] == true,
      summary: data['summary']?.toString() ?? '',
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }
}

class CropSuitability {
  final Map<String, double> scores;
  final String basis;
  final DateTime timestamp;

  const CropSuitability({
    required this.scores,
    this.basis = 'Rule-based v1',
    required this.timestamp,
  });

  factory CropSuitability.fromMap(Map<Object?, Object?> data) {
    final scores = <String, double>{};
    for (final entry in data.entries) {
      if (entry.key != 'basis' && entry.key != 'timestamp') {
        final val = entry.value;
        if (val is num) scores[entry.key.toString()] = val.toDouble();
      }
    }
    return CropSuitability(
      scores: scores,
      basis: data['basis']?.toString() ?? 'Rule-based v1',
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }

  String get topCrop {
    if (scores.isEmpty) return 'Unknown';
    return scores.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }
}

class CropRecommendation {
  final String bestCrop;
  final double bestScore;
  final String matchLevel;
  final List<String> reasons;
  final DateTime timestamp;

  const CropRecommendation({
    required this.bestCrop,
    required this.bestScore,
    this.matchLevel = 'Moderate',
    this.reasons = const [],
    required this.timestamp,
  });

  factory CropRecommendation.fromMap(Map<Object?, Object?> data) {
    final rawReasons = data['reasons'];
    List<String> reasons = [];
    if (rawReasons is List) {
      reasons = rawReasons.map((r) => r.toString()).toList();
    }
    return CropRecommendation(
      bestCrop: data['bestCrop']?.toString() ?? 'Unknown',
      bestScore: (data['bestScore'] as num?)?.toDouble() ?? 0.0,
      matchLevel: data['matchLevel']?.toString() ?? 'Moderate',
      reasons: reasons,
      timestamp: data['timestamp'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num).toInt(),
            )
          : DateTime.now(),
    );
  }
}
