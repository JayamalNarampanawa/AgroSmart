import 'dart:async';

import 'package:firebase_database/firebase_database.dart';

import '../models/analytics_point.dart';
import '../models/farm_profile.dart';
import '../models/sensor_data.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  late final DatabaseReference _root;

  Future<void> initialize() async {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    _root = FirebaseDatabase.instance.ref('AgroSmart');
    _root.keepSynced(true);
    _root.child('currentData').keepSynced(true);
    _root.child('history').keepSynced(true);
    _root.child('analytics').keepSynced(true);
    _root.child('farmProfile').keepSynced(true);
  }

  Stream<SensorData?> currentDataStream() {
    return _root.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return null;
      final map = Map<dynamic, dynamic>.from(value);
      final current = map['currentData'];
      if (current is Map) {
        return SensorData.fromMap(Map<dynamic, dynamic>.from(current));
      }
      final hasSensorKeys = map.containsKey('temperature') ||
          map.containsKey('Temperature') ||
          map.containsKey('humidity') ||
          map.containsKey('Humidity') ||
          map.containsKey('soilMoisture') ||
          map.containsKey('SoilMoisture') ||
          map.containsKey('lightLevel') ||
          map.containsKey('LightLevel') ||
          map.containsKey('Irrigation') ||
          map.containsKey('pumpStatus');
      if (hasSensorKeys) {
        return SensorData.fromMap(map);
      }
      return null;
    });
  }

  Stream<List<SensorData>> historyStream({int limit = 50}) {
    final ref = _root.child('history/logs');
    final query = ref.orderByChild('timestamp').limitToLast(limit);
    return query.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <SensorData>[];
      final list = value.values
          .whereType<Map>()
          .map((item) => SensorData.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  Stream<List<AnalyticsPoint>> analyticsStream({int limit = 120}) {
    final ref = _root.child('analytics/timeseries');
    final query = ref.orderByChild('timestamp').limitToLast(limit);
    return query.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return <AnalyticsPoint>[];
      final list = value.values
          .whereType<Map>()
          .map((item) => AnalyticsPoint.fromMap(Map<dynamic, dynamic>.from(item)))
          .toList();
      list.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return list;
    });
  }

  Stream<FarmProfile> farmProfileStream() {
    return _root.child('farmProfile').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return FarmProfile.fromMap(Map<dynamic, dynamic>.from(value));
      }
      return FarmProfile.fromMap(null);
    });
  }

  Future<void> updateFarmProfile(FarmProfile profile) async {
    await _root.child('farmProfile').update(profile.toMap());
  }
}

