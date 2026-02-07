import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: StreamBuilder<List<SensorData>>(
          stream: FirebaseService.instance.historyStream(limit: 60),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? [];
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
              children: [
                Text(
                  'Activity Logs',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 10),
                if (logs.isEmpty)
                  const Text('No logs yet', style: TextStyle(color: Colors.white60))
                else
                  ...logs.reversed.map((log) => _LogTile(log: log)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final SensorData log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d, HH:mm').format(log.timestamp);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(time, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white70)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 6,
              children: [
                _chip('Temp', '${log.temperature?.toStringAsFixed(1) ?? '--'}°C'),
                _chip('Humidity', '${log.humidity?.toStringAsFixed(1) ?? '--'}%'),
                _chip('Soil', log.soilMoisture?.toStringAsFixed(0) ?? '--'),
                _chip('Light', log.lightLevel?.toStringAsFixed(0) ?? '--'),
                _chip('Pump', log.pumpStatus ? 'ON' : 'OFF'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Text('$label: $value', style: const TextStyle(fontSize: 12)),
    );
  }
}
