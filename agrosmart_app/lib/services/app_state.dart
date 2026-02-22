import 'package:flutter/foundation.dart';
import '../models/sensor_data.dart';
import '../models/farm_profile.dart';
import '../models/ai_result.dart';
import '../models/crop_database.dart';
import '../services/firebase_service.dart';
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  // ── Sensor data ──────────────────────────────────────────────────────────
  SensorData? _sensor;
  SensorData? get sensor => _sensor;

  // ── Farm profile ──────────────────────────────────────────────────────────
  FarmProfile _farmProfile = const FarmProfile();
  FarmProfile get farmProfile => _farmProfile;

  // ── AI data ──────────────────────────────────────────────────────────────
  AIInsight? _insight;
  AIInsight? get insight => _insight;

  CropSuitability? _suitability;
  CropSuitability? get suitability => _suitability;

  CropRecommendation? _recommendation;
  CropRecommendation? get recommendation => _recommendation;

  // ── Connection / loading ──────────────────────────────────────────────────
  bool _loading = true;
  bool get loading => _loading;

  bool _connected = false;
  bool get connected => _connected;

  String? _error;
  String? get error => _error;

  // ── History (for charts) ──────────────────────────────────────────────────
  // Updated via separate stream in screen
  DateTime? _lastUpdated;
  DateTime? get lastUpdated => _lastUpdated;

  // ── Dark mode ─────────────────────────────────────────────────────────────
  bool _darkMode = true;
  bool get darkMode => _darkMode;
  void toggleDarkMode() {
    _darkMode = !_darkMode;
    notifyListeners();
  }

  // ── Navigation index ──────────────────────────────────────────────────────
  int _navIndex = 0;
  int get navIndex => _navIndex;
  void setNavIndex(int i) {
    _navIndex = i;
    notifyListeners();
  }

  // ── Services ──────────────────────────────────────────────────────────────
  final FirebaseService _fb = FirebaseService();
  final NotificationService _notif = NotificationService();

  void initialize() {
    _notif.initialize();
    _subscribeToStreams();
  }

  void _subscribeToStreams() {
    // Sensor stream
    _fb.sensorStream.listen(
      (data) {
        _loading = false;
        _connected = true;
        if (data != null) {
          _sensor = data;
          _lastUpdated = DateTime.now();
          _checkNotifications(data);
        }
        notifyListeners();
      },
      onError: (e) {
        _loading = false;
        _connected = false;
        _error = e.toString();
        notifyListeners();
      },
    );

    // Farm profile stream
    _fb.farmProfileStream.listen((profile) {
      _farmProfile = profile;
      notifyListeners();
    });

    // AI streams
    _fb.insightStream.listen((insight) {
      _insight = insight;
      notifyListeners();
    });

    _fb.suitabilityStream.listen((s) {
      _suitability = s;
      notifyListeners();
    });

    _fb.recommendationStream.listen((r) {
      _recommendation = r;
      notifyListeners();
    });
  }

  void _checkNotifications(SensorData data) {
    _notif.checkThresholds(
      temperature: data.temperature,
      humidity: data.humidity,
      soilWetnessPct: data.soilWetnessPercent(),
      lightLevel: data.lightLevel,
      pumpStatus: data.pumpStatus,
    );
  }

  // ── Farm profile update ───────────────────────────────────────────────────
  Future<void> saveFarmProfile(FarmProfile profile) async {
    await _fb.updateFarmProfile(profile);
    _farmProfile = profile;
    notifyListeners();
  }

  // ── Crop scoring (for soil analysis page) ────────────────────────────────
  List<MapEntry<CropInfo, double>> scoreCrops({
    required double temperature,
    required double humidity,
    required double n,
    required double p,
    required double k,
    required double ph,
    double rainfall = 100,
    String? categoryFilter,
  }) {
    final crops = categoryFilter == null
        ? cropDatabase
        : cropDatabase.where((c) => c.category == categoryFilter).toList();

    final scored =
        crops
            .map(
              (crop) => MapEntry(
                crop,
                crop.score(
                  temperature: temperature,
                  humidity: humidity,
                  n: n,
                  p: p,
                  k: k,
                  ph: ph,
                  rainfall: rainfall,
                ),
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return scored;
  }

  // ── Computed getters ──────────────────────────────────────────────────────
  String get soilStatusLabel {
    if (_sensor == null) return 'Unknown';
    return _sensor!.soilStatus;
  }

  String get irrigationLabel {
    if (_sensor == null) return 'OFF';
    return _sensor!.irrigationAdvice;
  }

  bool get isLive =>
      _lastUpdated != null &&
      DateTime.now().difference(_lastUpdated!).inMinutes < 5;
}
