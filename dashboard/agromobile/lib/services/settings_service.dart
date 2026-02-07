import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class SettingsService {
  SettingsService._();

  static final SettingsService instance = SettingsService._();

  static const _boxName = 'settings';
  static const _themeKey = 'theme_mode';

  late Box _box;
  final ValueNotifier<ThemeMode> themeMode = ValueNotifier<ThemeMode>(ThemeMode.dark);

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    final stored = _box.get(_themeKey) as String?;
    if (stored == 'light') {
      themeMode.value = ThemeMode.light;
    } else if (stored == 'system') {
      themeMode.value = ThemeMode.system;
    } else {
      themeMode.value = ThemeMode.dark;
    }
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
}

