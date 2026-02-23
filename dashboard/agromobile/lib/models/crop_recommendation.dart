class NpkPhRange {
  final double nMin, nMax;
  final double pMin, pMax;
  final double kMin, kMax;
  final double phMin, phMax;

  const NpkPhRange({
    required this.nMin,
    required this.nMax,
    required this.pMin,
    required this.pMax,
    required this.kMin,
    required this.kMax,
    required this.phMin,
    required this.phMax,
  });

  factory NpkPhRange.fromJson(Map<String, dynamic> json) {
    return NpkPhRange(
      nMin: (json['nMin'] ?? 0).toDouble(),
      nMax: (json['nMax'] ?? 0).toDouble(),
      pMin: (json['pMin'] ?? 0).toDouble(),
      pMax: (json['pMax'] ?? 0).toDouble(),
      kMin: (json['kMin'] ?? 0).toDouble(),
      kMax: (json['kMax'] ?? 0).toDouble(),
      phMin: (json['phMin'] ?? 0).toDouble(),
      phMax: (json['phMax'] ?? 0).toDouble(),
    );
  }
}

class CropRecommendation {
  final String cropName;
  final double fitScore;
  final String confidence;
  final String reason;
  final NpkPhRange idealRange;

  CropRecommendation({
    required this.cropName,
    required this.fitScore,
    required this.confidence,
    required this.reason,
    required this.idealRange,
  });

  factory CropRecommendation.fromJson(Map<String, dynamic> json) {
    return CropRecommendation(
      cropName: json['cropName'] ?? '',
      fitScore: (json['fitScore'] ?? 0).toDouble(),
      confidence: json['confidence'] ?? 'Low',
      reason: json['reason'] ?? '',
      idealRange: NpkPhRange.fromJson(
        json['idealRange'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}
