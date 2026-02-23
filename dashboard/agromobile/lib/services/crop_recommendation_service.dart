import '../models/crop_recommendation.dart';
import '../models/farm_profile.dart';
import 'api_service.dart';

class _CropEntry {
  final String name;
  final NpkPhRange range;

  const _CropEntry({required this.name, required this.range});
}

class CropRecommendationService {
  CropRecommendationService._();

  static final CropRecommendationService instance =
      CropRecommendationService._();

  bool useApiEnhancement = false;

  static const List<_CropEntry> _crops = [
    _CropEntry(
      name: 'Rice',
      range: NpkPhRange(
          nMin: 80,
          nMax: 120,
          pMin: 20,
          pMax: 40,
          kMin: 40,
          kMax: 80,
          phMin: 5.0,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Maize',
      range: NpkPhRange(
          nMin: 80,
          nMax: 120,
          pMin: 30,
          pMax: 60,
          kMin: 20,
          kMax: 60,
          phMin: 5.5,
          phMax: 7.5),
    ),
    _CropEntry(
      name: 'Tea',
      range: NpkPhRange(
          nMin: 20,
          nMax: 50,
          pMin: 10,
          pMax: 30,
          kMin: 20,
          kMax: 50,
          phMin: 4.5,
          phMax: 5.5),
    ),
    _CropEntry(
      name: 'Coconut',
      range: NpkPhRange(
          nMin: 30,
          nMax: 60,
          pMin: 20,
          pMax: 40,
          kMin: 80,
          kMax: 120,
          phMin: 5.5,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Black Pepper',
      range: NpkPhRange(
          nMin: 20,
          nMax: 50,
          pMin: 20,
          pMax: 40,
          kMin: 50,
          kMax: 100,
          phMin: 5.5,
          phMax: 6.5),
    ),
    _CropEntry(
      name: 'Cinnamon',
      range: NpkPhRange(
          nMin: 20,
          nMax: 40,
          pMin: 10,
          pMax: 25,
          kMin: 30,
          kMax: 60,
          phMin: 5.0,
          phMax: 6.5),
    ),
    _CropEntry(
      name: 'Rubber',
      range: NpkPhRange(
          nMin: 10,
          nMax: 30,
          pMin: 10,
          pMax: 25,
          kMin: 10,
          kMax: 30,
          phMin: 4.0,
          phMax: 6.0),
    ),
    _CropEntry(
      name: 'Coffee',
      range: NpkPhRange(
          nMin: 20,
          nMax: 40,
          pMin: 10,
          pMax: 20,
          kMin: 20,
          kMax: 40,
          phMin: 5.0,
          phMax: 6.5),
    ),
    _CropEntry(
      name: 'Banana',
      range: NpkPhRange(
          nMin: 60,
          nMax: 100,
          pMin: 20,
          pMax: 40,
          kMin: 100,
          kMax: 150,
          phMin: 5.5,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Sugarcane',
      range: NpkPhRange(
          nMin: 80,
          nMax: 120,
          pMin: 30,
          pMax: 60,
          kMin: 60,
          kMax: 100,
          phMin: 6.0,
          phMax: 7.5),
    ),
    _CropEntry(
      name: 'Tomato',
      range: NpkPhRange(
          nMin: 80,
          nMax: 120,
          pMin: 60,
          pMax: 80,
          kMin: 60,
          kMax: 100,
          phMin: 6.0,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Chili',
      range: NpkPhRange(
          nMin: 60,
          nMax: 100,
          pMin: 40,
          pMax: 60,
          kMin: 40,
          kMax: 80,
          phMin: 6.0,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Potato',
      range: NpkPhRange(
          nMin: 80,
          nMax: 120,
          pMin: 60,
          pMax: 80,
          kMin: 80,
          kMax: 120,
          phMin: 5.0,
          phMax: 6.5),
    ),
    _CropEntry(
      name: 'Soybean',
      range: NpkPhRange(
          nMin: 20,
          nMax: 40,
          pMin: 40,
          pMax: 60,
          kMin: 40,
          kMax: 80,
          phMin: 6.0,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Wheat',
      range: NpkPhRange(
          nMin: 60,
          nMax: 100,
          pMin: 20,
          pMax: 40,
          kMin: 20,
          kMax: 40,
          phMin: 6.0,
          phMax: 7.5),
    ),
    _CropEntry(
      name: 'Groundnut',
      range: NpkPhRange(
          nMin: 10,
          nMax: 20,
          pMin: 40,
          pMax: 60,
          kMin: 20,
          kMax: 40,
          phMin: 6.0,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Lentil',
      range: NpkPhRange(
          nMin: 10,
          nMax: 20,
          pMin: 40,
          pMax: 60,
          kMin: 20,
          kMax: 40,
          phMin: 6.0,
          phMax: 7.5),
    ),
    _CropEntry(
      name: 'Mango',
      range: NpkPhRange(
          nMin: 40,
          nMax: 70,
          pMin: 20,
          pMax: 40,
          kMin: 40,
          kMax: 80,
          phMin: 5.5,
          phMax: 7.5),
    ),
    _CropEntry(
      name: 'Papaya',
      range: NpkPhRange(
          nMin: 60,
          nMax: 100,
          pMin: 30,
          pMax: 50,
          kMin: 60,
          kMax: 100,
          phMin: 5.5,
          phMax: 7.0),
    ),
    _CropEntry(
      name: 'Cotton',
      range: NpkPhRange(
          nMin: 80,
          nMax: 120,
          pMin: 40,
          pMax: 60,
          kMin: 20,
          kMax: 40,
          phMin: 6.0,
          phMax: 7.5),
    ),
    _CropEntry(
      name: 'Chickpea',
      range: NpkPhRange(
          nMin: 20,
          nMax: 40,
          pMin: 40,
          pMax: 60,
          kMin: 20,
          kMax: 40,
          phMin: 6.0,
          phMax: 8.0),
    ),
    _CropEntry(
      name: 'Mung Beans',
      range: NpkPhRange(
          nMin: 15,
          nMax: 25,
          pMin: 40,
          pMax: 60,
          kMin: 20,
          kMax: 40,
          phMin: 6.2,
          phMax: 7.2),
    ),
    _CropEntry(
      name: 'Kidney Beans',
      range: NpkPhRange(
          nMin: 40,
          nMax: 60,
          pMin: 50,
          pMax: 70,
          kMin: 30,
          kMax: 50,
          phMin: 6.0,
          phMax: 7.0),
    ),
  ];

  /// Score only the crops whose names are in [cropNames].
  List<CropRecommendation> scoreForCrops({
    required double n,
    required double p,
    required double k,
    required double ph,
    required List<String> cropNames,
  }) {
    final names = cropNames.map((e) => e.toLowerCase()).toSet();
    final profile = FarmProfile(n: n, p: p, k: k, ph: ph, phIsDefault: false);
    final scored = _crops
        .where((c) => names.contains(c.name.toLowerCase()))
        .map((crop) {
      final score = _computeFitScore(n, p, k, ph, crop.range);
      final confidence =
          score >= 0.75 ? 'High' : (score >= 0.50 ? 'Medium' : 'Low');
      return CropRecommendation(
        cropName: crop.name,
        fitScore: score,
        confidence: confidence,
        reason: _generateReason(profile, crop.range),
        idealRange: crop.range,
      );
    }).toList();
    scored.sort((a, b) => b.fitScore.compareTo(a.fitScore));
    return scored;
  }

  Future<List<CropRecommendation>> getRecommendations(
    FarmProfile profile, {
    int topN = 5,
  }) async {
    if (useApiEnhancement) {
      try {
        return await _getApiRecommendations(profile, topN: topN);
      } catch (_) {
        // Fall back to local on any API failure
      }
    }
    return _getLocalRecommendations(profile, topN: topN);
  }

  List<CropRecommendation> _getLocalRecommendations(
    FarmProfile profile, {
    int topN = 5,
  }) {
    final scored = _crops.map((crop) {
      final score = _computeFitScore(
        profile.n,
        profile.p,
        profile.k,
        profile.ph,
        crop.range,
      );
      final confidence =
          score >= 0.75 ? 'High' : (score >= 0.50 ? 'Medium' : 'Low');
      return CropRecommendation(
        cropName: crop.name,
        fitScore: score,
        confidence: confidence,
        reason: _generateReason(profile, crop.range),
        idealRange: crop.range,
      );
    }).toList();
    scored.sort((a, b) => b.fitScore.compareTo(a.fitScore));
    return scored.take(topN).toList();
  }

  double _computeFitScore(
    double n,
    double p,
    double k,
    double ph,
    NpkPhRange r,
  ) {
    double nutrientScore(double val, double min, double max) {
      if (val >= min && val <= max) return 1.0;
      final range = max - min;
      if (range <= 0) return 0.0;
      final dist = val < min ? (min - val) : (val - max);
      return (1.0 - dist / range).clamp(0.0, 1.0);
    }

    final nS = nutrientScore(n, r.nMin, r.nMax);
    final pS = nutrientScore(p, r.pMin, r.pMax);
    final kS = nutrientScore(k, r.kMin, r.kMax);
    final phS = nutrientScore(ph, r.phMin, r.phMax);
    return nS * 0.30 + pS * 0.25 + kS * 0.25 + phS * 0.20;
  }

  String _generateReason(FarmProfile profile, NpkPhRange r) {
    final parts = <String>[];

    if (profile.n >= r.nMin && profile.n <= r.nMax) {
      parts.add('N is ideal');
    } else if (profile.n < r.nMin) {
      parts.add('N is low (needs ${r.nMin.toInt()}+)');
    } else {
      parts.add('N is high (ideal < ${r.nMax.toInt()})');
    }

    if (profile.p >= r.pMin && profile.p <= r.pMax) {
      parts.add('P is ideal');
    } else if (profile.p < r.pMin) {
      parts.add('P is low (needs ${r.pMin.toInt()}+)');
    } else {
      parts.add('P is high (ideal < ${r.pMax.toInt()})');
    }

    if (profile.k >= r.kMin && profile.k <= r.kMax) {
      parts.add('K is ideal');
    } else if (profile.k < r.kMin) {
      parts.add('K is low (needs ${r.kMin.toInt()}+)');
    } else {
      parts.add('K is high (ideal < ${r.kMax.toInt()})');
    }

    if (profile.ph >= r.phMin && profile.ph <= r.phMax) {
      parts.add('pH is ideal');
    } else if (profile.ph < r.phMin) {
      parts.add('pH is low (needs ${r.phMin.toStringAsFixed(1)}+)');
    } else {
      parts.add('pH is high (ideal < ${r.phMax.toStringAsFixed(1)})');
    }

    return parts.join(' | ');
  }

  Future<List<CropRecommendation>> _getApiRecommendations(
    FarmProfile profile, {
    int topN = 5,
  }) async {
    final result = await ApiService().getCropRecommendation(
      n: profile.n,
      p: profile.p,
      k: profile.k,
      ph: profile.ph,
    );
    final recs = result['recommendations'] as List? ?? [];
    final list = recs
        .map((e) =>
            CropRecommendation.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list.take(topN).toList();
  }
}
