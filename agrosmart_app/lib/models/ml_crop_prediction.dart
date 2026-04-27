class MlCropPrediction {
  final String predictedCrop;
  final double? confidence;
  final Map<String, double> probabilities;
  final String sourceUrl;

  const MlCropPrediction({
    required this.predictedCrop,
    required this.confidence,
    required this.probabilities,
    required this.sourceUrl,
  });

  factory MlCropPrediction.fromJson(
    Map<String, dynamic> json, {
    required String sourceUrl,
  }) {
    final rawCrop = json['predictedCrop'] ??
        json['predicted_crop'] ??
        json['crop'] ??
        json['prediction'];

    final rawProbs = json['probabilities'];
    final probabilities = <String, double>{};
    if (rawProbs is Map) {
      rawProbs.forEach((key, value) {
        final numericValue = _toDouble(value);
        if (key != null && numericValue != null) {
          probabilities[key.toString()] = numericValue;
        }
      });
    }

    return MlCropPrediction(
      predictedCrop: rawCrop?.toString() ?? 'Unknown',
      confidence: _toDouble(json['confidence']),
      probabilities: probabilities,
      sourceUrl: sourceUrl,
    );
  }

  List<MapEntry<String, double>> get topProbabilities {
    final sorted = probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.take(5).toList();
  }

  String get displayCrop => formatCropName(predictedCrop);

  static String formatCropName(String crop) {
    return crop
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
        .join(' ');
  }

  static double? _toDouble(Object? value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
