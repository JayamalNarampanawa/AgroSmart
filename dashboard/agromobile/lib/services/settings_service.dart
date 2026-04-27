import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _boxName = 'settings';
  static const _themeKey = 'theme_mode';
  static const _alertsEnabledKey = 'alerts_enabled';
  static const _highPriorityOnlyKey = 'high_priority_only';
  static const _soilMoistureThresholdKey = 'soil_moisture_threshold';
  static const _highTempThresholdKey = 'high_temp_threshold';

  late Box _box;
  final ValueNotifier<ThemeMode> themeMode =
      ValueNotifier<ThemeMode>(ThemeMode.light);
  final ValueNotifier<bool> alertsEnabled = ValueNotifier<bool>(true);
  final ValueNotifier<bool> highPriorityOnly = ValueNotifier<bool>(false);

  // Alert thresholds
  final ValueNotifier<double> soilMoistureDryThreshold =
      ValueNotifier<double>(3500.0);
  final ValueNotifier<double> highTempThreshold = ValueNotifier<double>(35.0);

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    final stored = _box.get(_themeKey) as String?;
    if (stored == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (stored == 'system') {
      themeMode.value = ThemeMode.system;
    } else {
      themeMode.value = ThemeMode.light;
    }
    alertsEnabled.value =
        _box.get(_alertsEnabledKey, defaultValue: true) as bool;
    highPriorityOnly.value =
        _box.get(_highPriorityOnlyKey, defaultValue: false) as bool;

    soilMoistureDryThreshold.value =
        (_box.get(_soilMoistureThresholdKey, defaultValue: 3500.0) as num)
            .toDouble();
    highTempThreshold.value =
        (_box.get(_highTempThresholdKey, defaultValue: 35.0) as num).toDouble();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
      ThemeMode.dark => 'dark',
    };
    await _box.put(_themeKey, value);
  }

  Future<void> setAlertsEnabled(bool value) async {
    alertsEnabled.value = value;
    await _box.put(_alertsEnabledKey, value);
  }

  Future<void> setHighPriorityOnly(bool value) async {
    highPriorityOnly.value = value;
    await _box.put(_highPriorityOnlyKey, value);
  }

  Future<void> setSoilMoistureDryThreshold(double value) async {
    soilMoistureDryThreshold.value = value;
    await _box.put(_soilMoistureThresholdKey, value);
  }

  Future<void> setHighTempThreshold(double value) async {
    highTempThreshold.value = value;
    await _box.put(_highTempThresholdKey, value);
  }
}
