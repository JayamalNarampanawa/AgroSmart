import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Threshold trackers (to avoid spamming)
  bool _soilDryAlertSent = false;
  bool _heatAlertSent = false;
  bool _lowLightAlertSent = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestSoundPermission: true,
      requestBadgePermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);
    _initialized = true;
    debugPrint('NotificationService initialized');
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
    Importance importance = Importance.high,
  }) async {
    if (!_initialized) await initialize();

    final androidDetails = AndroidNotificationDetails(
      'agrosmart_alerts',
      'AgroSmart Alerts',
      channelDescription: 'Real-time sensor threshold alerts',
      importance: importance,
      priority: Priority.high,
      color: const Color.fromARGB(255, 6, 182, 212),
      playSound: true,
      enableVibration: true,
    );
    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, details, payload: payload);
  }

  // ── Threshold checks ──────────────────────────────────────────────────────

  /// Call this whenever new sensor data arrives.
  Future<void> checkThresholds({
    required double temperature,
    required double humidity,
    required double soilWetnessPct,
    required double lightLevel,
    required bool pumpStatus,
  }) async {
    // Soil dry alert (wetness < 25%)
    if (soilWetnessPct < 25 && !_soilDryAlertSent) {
      _soilDryAlertSent = true;
      await _show(
        id: 1,
        title: '🌱 Irrigation Needed',
        body:
            'Soil moisture is critically low (${soilWetnessPct.toStringAsFixed(0)}%). Consider turning on the pump.',
      );
    } else if (soilWetnessPct >= 35) {
      _soilDryAlertSent = false; // reset
    }

    // Heat risk alert (temperature > 35°C)
    if (temperature > 35 && !_heatAlertSent) {
      _heatAlertSent = true;
      await _show(
        id: 2,
        title: '🌡️ High Temperature Alert',
        body:
            'Temperature has reached ${temperature.toStringAsFixed(1)}°C. Risk of crop heat stress.',
      );
    } else if (temperature <= 32) {
      _heatAlertSent = false;
    }

    // Low light alert (< 500 lux)
    if (lightLevel < 500 && !_lowLightAlertSent) {
      _lowLightAlertSent = true;
      await _show(
        id: 3,
        title: '☁️ Low Light Warning',
        body:
            'Light level is ${lightLevel.toStringAsFixed(0)} lux. Crops may underperform today.',
        importance: Importance.defaultImportance,
      );
    } else if (lightLevel >= 700) {
      _lowLightAlertSent = false;
    }
  }

  Future<void> showTestNotification() => _show(
    id: 99,
    title: '✅ AgroSmart Notifications Active',
    body: 'You will receive alerts when sensor thresholds are breached.',
  );

  Future<void> cancelAll() => _notifications.cancelAll();
}
