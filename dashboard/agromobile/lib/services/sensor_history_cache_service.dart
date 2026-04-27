import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/sensor_data.dart';

class SensorHistoryCacheService {
  SensorHistoryCacheService._();

  static final SensorHistoryCacheService instance =
      SensorHistoryCacheService._();

  static const _boxName = 'sensor_history_cache';
  static const _maxEntries = 240;
  static const _minimumSampleGap = Duration(seconds: 45);

  late Box _box;
  final ValueNotifier<List<SensorData>> history =
      ValueNotifier<List<SensorData>>([]);

  Future<void> initialize() async {
    _box = await Hive.openBox(_boxName);
    _loadFromBox();
    _box.watch().listen((_) => _loadFromBox());
  }

  Future<void> cacheSnapshot(SensorData? data) async {
    if (data == null || !_hasSensorValue(data)) return;

    final current = history.value;
    if (current.isNotEmpty) {
      final last = current.last;
      final tooSoon =
          data.timestamp.difference(last.timestamp).abs() < _minimumSampleGap;
      if (tooSoon && _sameReadings(last, data)) return;
    }

    final key = data.timestamp.millisecondsSinceEpoch.toString();
    await _box.put(key, _toMap(data));
    await _trimOldEntries();
    _loadFromBox();
  }

  Future<void> cacheSnapshots(List<SensorData> items) async {
    var changed = false;
    for (final item in items) {
      if (!_hasSensorValue(item)) continue;
      final key = item.timestamp.millisecondsSinceEpoch.toString();
      if (!_box.containsKey(key)) {
        await _box.put(key, _toMap(item));
        changed = true;
      }
    }
    if (!changed) return;
    await _trimOldEntries();
    _loadFromBox();
  }

  Future<void> clear() async {
    await _box.clear();
    history.value = [];
  }

  List<SensorData> mergeWithRemote(List<SensorData> remote) {
    final byMinute = <int, SensorData>{};
    for (final item in [...history.value, ...remote]) {
      final key = item.timestamp.millisecondsSinceEpoch ~/ 60000;
      byMinute[key] = item;
    }
    final merged = byMinute.values.toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return merged.length > _maxEntries
        ? merged.sublist(merged.length - _maxEntries)
        : merged;
  }

  void _loadFromBox() {
    final items = _box.values
        .whereType<Map>()
        .map((item) => SensorData.fromMap(Map<dynamic, dynamic>.from(item)))
        .toList()
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    history.value = items.length > _maxEntries
        ? items.sublist(items.length - _maxEntries)
        : items;
  }

  Future<void> _trimOldEntries() async {
    if (_box.length <= _maxEntries) return;
    final keys = _box.keys.toList()
      ..sort((a, b) => a.toString().compareTo(b.toString()));
    final deleteCount = _box.length - _maxEntries;
    await _box.deleteAll(keys.take(deleteCount));
  }

  Map<String, dynamic> _toMap(SensorData data) {
    return {
      'temperature': data.temperature,
      'humidity': data.humidity,
      'soilMoisture': data.soilMoisture,
      'lightLevel': data.lightLevel,
      'pumpStatus': data.pumpStatus,
      'waterLevel': data.waterLevelPercent,
      'timestamp': data.timestamp.millisecondsSinceEpoch,
    };
  }

  bool _hasSensorValue(SensorData data) {
    return data.temperature != null ||
        data.humidity != null ||
        data.soilMoisture != null ||
        data.lightLevel != null;
  }

  bool _sameReadings(SensorData a, SensorData b) {
    return a.temperature == b.temperature &&
        a.humidity == b.humidity &&
        a.soilMoisture == b.soilMoisture &&
        a.lightLevel == b.lightLevel &&
        a.pumpStatus == b.pumpStatus;
  }
}
