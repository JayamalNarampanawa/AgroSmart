import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/farm_profile.dart';
import '../models/ai_result.dart';
import '../models/sensor_history.dart';

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseDatabase _db = FirebaseDatabase.instance;
  static const String _root = 'AgroSmart';

  // ── References ─────────────────────────────────────────────────────────────
  DatabaseReference get _currentDataRef => _db.ref('$_root/currentData');

  DatabaseReference get _historyRef => _db.ref('$_root/history/logs');

  DatabaseReference get _farmProfileRef => _db.ref('$_root/farmProfile');

  DatabaseReference get _insightRef => _db.ref('$_root/ai/currentInsight');

  DatabaseReference get _suitabilityRef => _db.ref('$_root/ai/suitability');

  DatabaseReference get _recommendationRef =>
      _db.ref('$_root/ai/recommendation');

  // ── Live Sensor Stream ─────────────────────────────────────────────────────
  Stream<SensorData?> get sensorStream => _currentDataRef.onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) return null;
    try {
      return SensorData.fromMap(data as Map<Object?, Object?>);
    } catch (e) {
      debugPrint('SensorData parse error: $e');
      return null;
    }
  });

  // ── History (last N logs) ─────────────────────────────────────────────────
  Stream<List<SensorHistory>> historyStream({int limit = 50}) =>
      _historyRef.limitToLast(limit).onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return [];
        try {
          final map = data as Map<Object?, Object?>;
          final list = map.entries
              .map(
                (e) => SensorHistory.fromMap(
                  e.key.toString(),
                  e.value as Map<Object?, Object?>,
                ),
              )
              .toList();
          list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
          return list;
        } catch (e) {
          debugPrint('History parse error: $e');
          return <SensorHistory>[];
        }
      });

  // ── Farm Profile ──────────────────────────────────────────────────────────
  Stream<FarmProfile> get farmProfileStream =>
      _farmProfileRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return const FarmProfile();
        try {
          return FarmProfile.fromMap(data as Map<Object?, Object?>);
        } catch (e) {
          debugPrint('FarmProfile parse error: $e');
          return const FarmProfile();
        }
      });

  Future<void> updateFarmProfile(FarmProfile profile) async {
    await _farmProfileRef.update(profile.toMap());
  }

  // ── AI Insight ──────────────────────────────────────────────────────────
  Stream<AIInsight?> get insightStream => _insightRef.onValue.map((event) {
    final data = event.snapshot.value;
    if (data == null) return null;
    try {
      return AIInsight.fromMap(data as Map<Object?, Object?>);
    } catch (e) {
      debugPrint('AIInsight parse error: $e');
      return null;
    }
  });

  // ── AI Suitability ──────────────────────────────────────────────────────
  Stream<CropSuitability?> get suitabilityStream =>
      _suitabilityRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return null;
        try {
          return CropSuitability.fromMap(data as Map<Object?, Object?>);
        } catch (e) {
          debugPrint('Suitability parse error: $e');
          return null;
        }
      });

  // ── AI Recommendation ─────────────────────────────────────────────────────
  Stream<CropRecommendation?> get recommendationStream =>
      _recommendationRef.onValue.map((event) {
        final data = event.snapshot.value;
        if (data == null) return null;
        try {
          return CropRecommendation.fromMap(data as Map<Object?, Object?>);
        } catch (e) {
          debugPrint('Recommendation parse error: $e');
          return null;
        }
      });

  // ── One-time reads ─────────────────────────────────────────────────────────
  Future<SensorData?> getCurrentSensorData() async {
    final snap = await _currentDataRef.get();
    if (!snap.exists || snap.value == null) return null;
    return SensorData.fromMap(snap.value as Map<Object?, Object?>);
  }

  Future<FarmProfile> getFarmProfile() async {
    final snap = await _farmProfileRef.get();
    if (!snap.exists || snap.value == null) return const FarmProfile();
    return FarmProfile.fromMap(snap.value as Map<Object?, Object?>);
  }

  // ── Irrigation stats from history ─────────────────────────────────────────
  Future<Map<String, int>> getPumpActivityByDay({int days = 7}) async {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final snap = await _historyRef
        .orderByChild('timestamp')
        .startAt(cutoff.millisecondsSinceEpoch)
        .get();

    final Map<String, int> counts = {};

    if (!snap.exists || snap.value == null) return counts;

    final map = snap.value as Map<Object?, Object?>;
    for (final entry in map.entries) {
      try {
        final record = SensorHistory.fromMap(
          entry.key.toString(),
          entry.value as Map<Object?, Object?>,
        );
        if (record.pumpStatus) {
          final dayKey = '${record.timestamp.month}/${record.timestamp.day}';
          counts[dayKey] = (counts[dayKey] ?? 0) + 1;
        }
      } catch (_) {}
    }
    return counts;
  }
}
