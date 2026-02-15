import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/sensor_data.dart';

class AlertService {
  AlertService._();

  static final AlertService instance = AlertService._();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final Map<String, DateTime> _lastNotified = {};

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings);
    const channel = AndroidNotificationChannel(
      'agrosmart_alerts',
      'AgroSmart Alerts',
      description: 'Critical sensor alerts',
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  Future<void> checkAndNotify(SensorData data) async {
    final alerts = <String, String>{};
    if ((data.temperature ?? 0) > 35) {
      alerts['temperature'] = 'Temperature too high';
    }
    if ((data.soilMoisture ?? 0) > 2200) {
      alerts['soil'] = 'Soil is very dry';
    }
    if ((data.lightLevel ?? 0) < 100) {
      alerts['light'] = 'Light level low';
    }

    for (final entry in alerts.entries) {
      final last = _lastNotified[entry.key];
      final now = DateTime.now();
      if (last != null && now.difference(last).inMinutes < 10) {
        continue;
      }
      _lastNotified[entry.key] = now;
      await _plugin.show(
        entry.key.hashCode,
        'AgroSmart Alert',
        entry.value,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'agrosmart_alerts',
            'AgroSmart Alerts',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
      );
    }
  }
}

