import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';
import '../models/sensor_data.dart';
import 'alert_service.dart';
import 'firebase_service.dart';
import 'settings_service.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final ValueNotifier<List<NotificationModel>> notifications =
      ValueNotifier([]);
  final ValueNotifier<int> unreadCount = ValueNotifier(0);

  StreamSubscription<SensorData?>? _sensorSubscription;
  SharedPreferences? _prefs;

  bool _previousPumpStatus = false;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadNotifications();
    _startMonitoring();
  }

  void _startMonitoring() {
    _sensorSubscription =
        FirebaseService.instance.currentDataStream().listen(_processSensorData);

    // Process any already-cached data so the first reading is never missed
    final cached = FirebaseService.instance.latestSensorData;
    if (cached != null) _processSensorData(cached);
  }

  void _processSensorData(SensorData? data) {
    if (data == null) return;

    final settings = SettingsService.instance;

    // Also trigger OS push notifications
    AlertService.instance.checkAndNotify(data);

    // Check soil moisture (higher raw ADC value = drier soil)
    if (data.soilMoisture != null &&
        data.soilMoisture! > settings.soilMoistureDryThreshold.value) {
      addNotification(
        title: 'Low Soil Moisture',
        message:
            'Soil moisture reading is ${data.soilMoisture!.toStringAsFixed(0)} '
            '(dry threshold: ${settings.soilMoistureDryThreshold.value.toStringAsFixed(0)}). '
            'Consider irrigation.',
        type: NotificationType.warning,
        priority: NotificationPriority.high,
        source: 'Live Sensors',
      );
    }

    // Check temperature
    if (data.temperature != null &&
        data.temperature! > settings.highTempThreshold.value) {
      addNotification(
        title: 'High Temperature Alert',
        message:
            'Temperature is ${data.temperature!.toStringAsFixed(1)}\u00B0C. '
            'Monitor crops closely.',
        type: NotificationType.alert,
        priority: NotificationPriority.high,
        source: 'Live Sensors',
      );
    }

    // Irrigation status change (only notify on transitions)
    if (data.pumpStatus && !_previousPumpStatus) {
      addNotification(
        title: 'Irrigation Started',
        message: 'Water pump is now active.',
        type: NotificationType.info,
        priority: NotificationPriority.low,
        source: 'Irrigation',
      );
    } else if (!data.pumpStatus && _previousPumpStatus) {
      addNotification(
        title: 'Irrigation Stopped',
        message: 'Water pump has been turned off.',
        type: NotificationType.info,
        priority: NotificationPriority.low,
        source: 'Irrigation',
      );
    }
    _previousPumpStatus = data.pumpStatus;
  }

  void addNotification({
    required String title,
    required String message,
    required NotificationType type,
    required NotificationPriority priority,
    String source = 'System',
    bool showSystemAlert = false,
    Duration duplicateWindow = const Duration(minutes: 5),
  }) {
    if (!SettingsService.instance.alertsEnabled.value) return;
    if (SettingsService.instance.highPriorityOnly.value &&
        (priority == NotificationPriority.low ||
            priority == NotificationPriority.normal)) {
      return;
    }

    // Check if similar notification exists in last 5 minutes
    final now = DateTime.now();
    final recentNotifications = notifications.value.where((n) {
      return n.title == title &&
          n.source == source &&
          now.difference(n.timestamp) < duplicateWindow;
    });

    if (recentNotifications.isNotEmpty) return; // Avoid duplicates

    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      message: message,
      type: type,
      timestamp: now,
      priority: priority,
      source: source,
    );

    final updated = [notification, ...notifications.value];
    notifications.value = updated;
    _updateUnreadCount();
    _saveNotifications();

    if (showSystemAlert ||
        priority == NotificationPriority.high ||
        priority == NotificationPriority.critical) {
      unawaited(
        AlertService.instance.showSystemNotification(
          title: title,
          message: message,
          id: notification.id.hashCode,
        ),
      );
    }
  }

  void notifyAuthSuccess(String email) {
    addNotification(
      title: 'Login Successful',
      message: 'Signed in as $email.',
      type: NotificationType.success,
      priority: NotificationPriority.normal,
      source: 'Authentication',
      duplicateWindow: const Duration(seconds: 10),
    );
  }

  void notifyAuthFailure(String email) {
    addNotification(
      title: 'Login Failed',
      message: 'Failed sign-in attempt for $email.',
      type: NotificationType.warning,
      priority: NotificationPriority.high,
      source: 'Authentication',
      showSystemAlert: true,
      duplicateWindow: const Duration(seconds: 10),
    );
  }

  void notifyLogout(String email) {
    addNotification(
      title: 'Signed Out',
      message: '$email signed out from the mobile app.',
      type: NotificationType.info,
      priority: NotificationPriority.normal,
      source: 'Authentication',
      duplicateWindow: const Duration(seconds: 10),
    );
  }

  void markAsRead(String id) {
    final updated = notifications.value.map((n) {
      return n.id == id ? n.copyWith(isRead: true) : n;
    }).toList();
    notifications.value = updated;
    _updateUnreadCount();
    _saveNotifications();
  }

  void markAllAsRead() {
    final updated =
        notifications.value.map((n) => n.copyWith(isRead: true)).toList();
    notifications.value = updated;
    _updateUnreadCount();
    _saveNotifications();
  }

  void clearAll() {
    notifications.value = [];
    unreadCount.value = 0;
    _saveNotifications();
  }

  void clearRead() {
    final updated = notifications.value.where((n) => !n.isRead).toList();
    notifications.value = updated;
    _updateUnreadCount();
    _saveNotifications();
  }

  void _updateUnreadCount() {
    unreadCount.value = notifications.value.where((n) => !n.isRead).length;
  }

  Future<void> _saveNotifications() async {
    if (_prefs == null) return;
    final jsonList =
        notifications.value.map((n) => jsonEncode(n.toMap())).toList();
    await _prefs!.setStringList('notifications', jsonList);
  }

  Future<void> _loadNotifications() async {
    if (_prefs == null) return;
    final jsonList = _prefs!.getStringList('notifications') ?? [];
    final loaded = jsonList
        .map((json) => NotificationModel.fromMap(jsonDecode(json)))
        .toList();
    notifications.value = loaded;
    _updateUnreadCount();
  }

  void dispose() {
    _sensorSubscription?.cancel();
    notifications.dispose();
    unreadCount.dispose();
  }
}
