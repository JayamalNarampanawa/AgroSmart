import 'package:flutter/material.dart';

import '../models/sensor_data.dart';

class AlertsPanel extends StatelessWidget {
  final SensorData? current;

  const AlertsPanel({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    if (current == null) {
      return const Text('No realtime data', style: TextStyle(color: Colors.white60));
    }
    final alerts = <_Alert>[];
    if ((current?.temperature ?? 0) > 35) {
      alerts.add(const _Alert('Temperature too high', _AlertLevel.high));
    }
    if ((current?.soilMoisture ?? 0) > 2200) {
      alerts.add(const _Alert('Soil is very dry', _AlertLevel.medium));
    }
    if ((current?.lightLevel ?? 0) < 100) {
      alerts.add(const _Alert('Light level low', _AlertLevel.low));
    }

    if (alerts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: const Color(0xFF10B981).withOpacity(0.12),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
        ),
        child: const Text('All readings normal', style: TextStyle(color: Color(0xFFBFF7E6))),
      );
    }

    return Column(
      children: alerts
          .map((alert) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: alert.background,
                  border: Border.all(color: alert.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert.message,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: alert.badge,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        alert.level.name.toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

enum _AlertLevel { high, medium, low }

class _Alert {
  final String message;
  final _AlertLevel level;

  const _Alert(this.message, this.level);

  Color get background {
    switch (level) {
      case _AlertLevel.high:
        return const Color(0xFFEF4444).withOpacity(0.12);
      case _AlertLevel.medium:
        return const Color(0xFFF59E0B).withOpacity(0.12);
      case _AlertLevel.low:
        return Colors.white.withOpacity(0.05);
    }
  }

  Color get border {
    switch (level) {
      case _AlertLevel.high:
        return const Color(0xFFEF4444).withOpacity(0.35);
      case _AlertLevel.medium:
        return const Color(0xFFF59E0B).withOpacity(0.3);
      case _AlertLevel.low:
        return Colors.white.withOpacity(0.15);
    }
  }

  Color get badge {
    switch (level) {
      case _AlertLevel.high:
        return const Color(0xFFEF4444);
      case _AlertLevel.medium:
        return const Color(0xFFF59E0B);
      case _AlertLevel.low:
        return Colors.white.withOpacity(0.2);
    }
  }
}
