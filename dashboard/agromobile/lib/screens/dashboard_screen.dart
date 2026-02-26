import 'package:flutter/material.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../widgets/glass_card.dart';
import '../widgets/notification_button.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  void _refresh() => setState(() {});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refresh,
          ),
          const NotificationButton(),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050A14),
              Color(0xFF0B1221),
              Color(0xFF050A14),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<SensorData?>(
            stream: FirebaseService.instance.currentDataStream(),
            initialData: FirebaseService.instance.latestSensorData,
            builder: (context, snapshot) {
              final data = snapshot.data;
              final soil = data?.soilMoisture;
              final humidity = data?.humidity;
              final light = data?.lightLevel;
              final pumpOn = data?.pumpStatus ?? false;
              final temp = data?.temperature;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Section
                    Text(
                      'System Status',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Live data from Firebase Realtime Database',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                    ),
                    const SizedBox(height: 24),

                    if (snapshot.connectionState == ConnectionState.waiting &&
                        data == null)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                      ),

                    if (snapshot.hasError)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          'Failed to load live data: ${snapshot.error}',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),

                    // Status Cards Grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 1.1,
                      children: [
                        _buildStatusCard(
                          'Temperature',
                          temp != null ? '${temp.toStringAsFixed(1)}°C' : '--',
                          Icons.thermostat,
                          const Color(0xFFFFA726),
                          _progress(temp, 0, 50),
                        ),
                        _buildStatusCard(
                          'Humidity',
                          humidity != null
                              ? '${humidity.toStringAsFixed(1)}%'
                              : '--',
                          Icons.water_drop,
                          const Color(0xFF00E5FF),
                          _progress(humidity, 0, 100),
                        ),
                        _buildStatusCard(
                          'Soil Moisture',
                          soil != null ? soil.toStringAsFixed(0) : '--',
                          Icons.grass,
                          const Color(0xFF00FFC2),
                          _progress(soil, 0, 3000),
                        ),
                        _buildStatusCard(
                          'Light Level',
                          light != null
                              ? '${light.toStringAsFixed(0)} lux'
                              : '--',
                          Icons.wb_sunny,
                          const Color(0xFFFFC107),
                          _progress(light, 0, 5000),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // System Health Indicators
                    Text(
                      'System Health',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                    ),
                    const SizedBox(height: 16),

                    GlassCard(
                      child: Column(
                        children: [
                          _buildHealthIndicator('Sensors', data != null),
                          const Divider(height: 24, color: Colors.white12),
                          _buildHealthIndicator('Connectivity',
                              snapshot.connectionState == ConnectionState.active),
                          const Divider(height: 24, color: Colors.white12),
                          _buildHealthIndicator('Power Supply', true),
                          const Divider(height: 24, color: Colors.white12),
                          _buildHealthIndicator('Water Pump', pumpOn),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  double _progress(double? value, double min, double max) {
    if (value == null) return 0.0;
    final clamped = value.clamp(min, max);
    return (clamped - min) / (max - min);
  }

  Widget _buildStatusCard(
      String title, String value, IconData icon, Color color, double progress) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon with glow effect
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.visible,
            ),
          ),
          const SizedBox(height: 6),
          // Progress indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthIndicator(String component, bool isHealthy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (isHealthy
                        ? const Color(0xFF00FFC2)
                        : const Color(0xFFFF5252))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: isHealthy
                    ? const Color(0xFF00FFC2)
                    : const Color(0xFFFF5252),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              component,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color:
                (isHealthy ? const Color(0xFF00FFC2) : const Color(0xFFFF5252))
                    .withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: (isHealthy
                      ? const Color(0xFF00FFC2)
                      : const Color(0xFFFF5252))
                  .withOpacity(0.3),
            ),
          ),
          child: Text(
            isHealthy ? 'Online' : 'Offline',
            style: TextStyle(
              color:
                  isHealthy ? const Color(0xFF00FFC2) : const Color(0xFFFF5252),
              fontWeight: FontWeight.bold,
              fontSize: 12,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}
