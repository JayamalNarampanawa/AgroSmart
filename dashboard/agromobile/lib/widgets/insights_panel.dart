import 'package:flutter/material.dart';

import '../models/sensor_data.dart';

class InsightsPanel extends StatelessWidget {
  final SensorData? current;

  const InsightsPanel({super.key, required this.current});

  @override
  Widget build(BuildContext context) {
    final soil = current?.soilMoisture;
    var soilStatus = 'Unknown';
    var suggestion = 'N/A';

    if (soil != null) {
      if (soil > 2200) {
        soilStatus = 'Dry';
        suggestion = 'Irrigation Recommended';
      } else if (soil > 1200) {
        soilStatus = 'Optimal';
        suggestion = 'No action';
      } else {
        soilStatus = 'Wet';
        suggestion = 'No irrigation';
      }
    }

    final env = current == null
        ? 'No data'
        : 'T:${current!.temperature?.toStringAsFixed(1) ?? '--'}°C · H:${current!.humidity?.toStringAsFixed(1) ?? '--'}%';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InsightTile(label: 'Soil Condition', value: soilStatus),
        const SizedBox(height: 10),
        _InsightTile(label: 'Suggestion', value: suggestion),
        const SizedBox(height: 10),
        _InsightTile(label: 'Environment', value: env),
      ],
    );
  }
}

class _InsightTile extends StatelessWidget {
  final String label;
  final String value;

  const _InsightTile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.6,
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

