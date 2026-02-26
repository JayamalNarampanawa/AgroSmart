import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';

class SoilMoistureScreen extends StatelessWidget {
  const SoilMoistureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Moisture Monitor'),
        centerTitle: true,
      ),
      body: StreamBuilder<SensorData?>(
        stream: FirebaseService.instance.currentDataStream(),
        initialData: FirebaseService.instance.latestSensorData,
        builder: (context, snapshot) {
          final moisture = snapshot.data?.soilMoisture;
          final moisturePct = (moisture ?? 0) / 40; // raw 0‑4000 -> percent
          final clampedPct = moisturePct.clamp(0.0, 1.0);

          Color _getMoistureColor(double value) {
            if (value < 30) return Colors.red;
            if (value < 60) return Colors.orange;
            return Colors.green;
          }

          String _getMoistureStatus(double value) {
            if (value < 30) return 'Low - Irrigation Needed';
            if (value < 60) return 'Moderate';
            return 'Optimal';
          }

          if (snapshot.connectionState == ConnectionState.waiting &&
              snapshot.data == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Card(
                  elevation: 8,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        const Text(
                          'Current Soil Moisture',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 24),
                        CircularPercentIndicator(
                          radius: 80.0,
                          lineWidth: 12.0,
                          percent: clampedPct,
                          center: Text(
                            moisture != null
                                ? moisture.toStringAsFixed(0)
                                : '--',
                            style: const TextStyle(
                                fontSize: 24, fontWeight: FontWeight.bold),
                          ),
                          progressColor: _getMoistureColor(clampedPct * 100),
                          backgroundColor: Colors.grey[200]!,
                          animation: true,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          moisture != null
                              ? _getMoistureStatus(clampedPct * 100)
                              : 'Waiting for data…',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Irrigation Tips',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        Text(
                            '• Water early morning or late evening to reduce evaporation.'),
                        SizedBox(height: 6),
                        Text(
                            '• Maintain moisture between 60-80% for most crops.'),
                        SizedBox(height: 6),
                        Text(
                            '• Use drip irrigation for efficient water usage.'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
