import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;

import '../models/analytics_point.dart';
import '../models/farm_profile.dart';
import '../models/scada_state.dart';
import '../models/sensor_data.dart';
import 'sensor_history_cache_service.dart';

class FirebaseService {
  FirebaseService._();

  static final FirebaseService instance = FirebaseService._();

  late final DatabaseReference _root;
  Stream<SensorData?>? _cachedCurrentDataStream;
  SensorData? _latestSensorData;

  /// The most recent [SensorData] emitted by [currentDataStream].
  /// Useful as `initialData` for StreamBuilder to avoid blank screens.
  SensorData? get latestSensorData => _latestSensorData;

  /// Top-level RTDB keys written by the IoT device.
  static const _sensorKeys = [
    'Temperature',
    'Humidity',
    'SoilMoisture',
    'LightLevel',
    'Irrigation',
  ];

  Future<void> initialize() async {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
    _root = FirebaseDatabase.instance.ref('AgroSmart');
    for (final key in _sensorKeys) {
      _root.child(key).keepSynced(true);
    }
    _root.child('history').keepSynced(true);
    _root.child('analytics').keepSynced(true);
    _root.child('farmProfile').keepSynced(true);
    _root.child('weather').keepSynced(true);
    _root.child('scada/control').keepSynced(true);
    _root.child('scada/events').keepSynced(true);
  }

  /// Listens to each top-level sensor key individually and combines them
  /// into a single [SensorData] stream. Each key change emits the latest
  /// combined snapshot.
  Stream<SensorData?> currentDataStream() {
    if (_cachedCurrentDataStream != null) return _cachedCurrentDataStream!;

    final controller = StreamController<SensorData?>.broadcast();
    final latest = <String, dynamic>{};

    void emit() {
      if (latest.isEmpty) {
        _latestSensorData = null;
        controller.add(null);
        return;
      }
      _latestSensorData =
          SensorData.fromMap(Map<dynamic, dynamic>.from(latest));
      SensorHistoryCacheService.instance.cacheSnapshot(_latestSensorData);
      controller.add(_latestSensorData);
    }

    for (final key in _sensorKeys) {
      _root.child(key).onValue.listen((event) {
        latest[key] = event.snapshot.value;
        emit();
      });
    }

    _cachedCurrentDataStream = controller.stream;
    return _cachedCurrentDataStream!;
  }

  Stream<Map<String, dynamic>?> weatherStream() {
    return _root.child('weather').onValue.map((event) {
      final v = event.snapshot.value;
      if (v is! Map) return null;
      return Map<String, dynamic>.from(v);
    });
  }

  Stream<bool> realtimeConnectionStream() {
    return FirebaseDatabase.instance.ref('.info/connected').onValue.map(
      (event) {
        return event.snapshot.value == true;
      },
    );
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
          .map((item) =>
              AnalyticsPoint.fromMap(Map<dynamic, dynamic>.from(item)))
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

  Stream<ScadaControlState> scadaControlStream() {
    return _root.child('scada/control').onValue.map((event) {
      final value = event.snapshot.value;
      if (value is Map) {
        return ScadaControlState.fromMap(Map<dynamic, dynamic>.from(value));
      }
      return ScadaControlState.initial();
    });
  }

  Stream<List<ScadaEvent>> scadaEventStream({int limit = 20}) {
    final query = _root
        .child('scada/events')
        .orderByChild('timestamp')
        .limitToLast(limit);
    return query.onValue.map((event) {
      final value = event.snapshot.value;
      if (value is! Map) return const <ScadaEvent>[];

      final items = value.entries
          .map(
            (entry) => ScadaEvent.fromMap(
              entry.key.toString(),
              entry.value is Map
                  ? Map<dynamic, dynamic>.from(entry.value as Map)
                  : null,
            ),
          )
          .toList();
      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    });
  }

  /// Toggle the irrigation pump on/off in RTDB.
  Future<void> togglePump() async {
    final current = _latestSensorData?.pumpStatus ?? false;
    await setPumpState(!current);
  }

  Future<void> setControlMode(
    bool autoMode, {
    String operatorLabel = 'SCADA',
  }) async {
    final command = autoMode ? 'MODE_AUTO' : 'MODE_MANUAL';
    await _root.child('scada/control').update({
      'autoMode': autoMode,
      'lastCommand': command,
      'lastCommandAt': DateTime.now().millisecondsSinceEpoch,
      'operatorLabel': operatorLabel,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await _appendScadaEvent(
      title: autoMode ? 'Switched to automatic mode' : 'Switched to manual mode',
      message: autoMode
          ? 'Pump commands will follow the automatic control strategy.'
          : 'Direct pump commands are enabled from the SCADA console.',
      source: operatorLabel,
      severity: ScadaEventSeverity.info,
    );
  }

  Future<void> setPumpState(
    bool on, {
    String operatorLabel = 'SCADA',
  }) async {
    final command = on ? 'PUMP_ON' : 'PUMP_OFF';
    await _root.child('Irrigation').set(on ? 'on' : 'off');
    await _root.child('scada/control').update({
      'lastCommand': command,
      'lastCommandAt': DateTime.now().millisecondsSinceEpoch,
      'operatorLabel': operatorLabel,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await _appendScadaEvent(
      title: on ? 'Pump started' : 'Pump stopped',
      message: on
          ? 'The irrigation pump was started from the SCADA console.'
          : 'The irrigation pump was stopped from the SCADA console.',
      source: operatorLabel,
      severity: on
          ? ScadaEventSeverity.success
          : ScadaEventSeverity.warning,
    );
  }

  Future<void> resetScadaAlarms({
    int acknowledged = 0,
    String operatorLabel = 'SCADA',
  }) async {
    await _root.child('scada/control').update({
      'lastCommand': 'RESET_ALARMS',
      'lastCommandAt': DateTime.now().millisecondsSinceEpoch,
      'operatorLabel': operatorLabel,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    await _appendScadaEvent(
      title: 'Alarm reset requested',
      message: acknowledged > 0
          ? '$acknowledged active alarm(s) were acknowledged by the operator.'
          : 'The operator cleared the current alarm acknowledgements.',
      source: operatorLabel,
      severity: ScadaEventSeverity.info,
    );
  }

  Future<void> _appendScadaEvent({
    required String title,
    required String message,
    required String source,
    required ScadaEventSeverity severity,
  }) async {
    final ref = _root.child('scada/events').push();
    await ref.set(
      ScadaEvent(
        id: ref.key ?? '',
        title: title,
        message: message,
        source: source,
        severity: severity,
        timestamp: DateTime.now(),
      ).toMap(),
    );
  }

  /// Fetch current weather from OpenWeatherMap and update RTDB /AgroSmart/weather
  Future<void> refreshWeatherFromOpenWeather({
    required double lat,
    required double lon,
    required String apiKey,
  }) async {
    final url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric');
    final res = await http.get(url).timeout(const Duration(seconds: 8));
    if (res.statusCode != 200) {
      throw Exception('OpenWeather HTTP ${res.statusCode}: ${res.body}');
    }
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final main = json['main'] as Map<String, dynamic>? ?? {};
    final wind = json['wind'] as Map<String, dynamic>? ?? {};
    final rain = json['rain'] as Map<String, dynamic>? ?? {};
    final desc =
        (json['weather'] is List && (json['weather'] as List).isNotEmpty)
            ? (json['weather'] as List).first['description']?.toString()
            : null;

    final data = {
      'description': desc ?? 'Unknown',
      'temperature': (main['temp'] ?? 0).toDouble(),
      'humidity': (main['humidity'] ?? 0).toDouble(),
      'windSpeed': (wind['speed'] ?? 0).toDouble(),
      'rainfall': (rain['1h'] ?? rain['3h'] ?? 0).toDouble(),
      'source': 'OpenWeatherMap',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };

    await _root.child('weather').update(data);
  }
}
