import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../widgets/glass_card.dart';

class LightDetectorScreen extends StatefulWidget {
  const LightDetectorScreen({super.key});

  @override
  State<LightDetectorScreen> createState() => _LightDetectorScreenState();
}

class _LightDetectorScreenState extends State<LightDetectorScreen> {
  final List<FlSpot> _lightData = [];
  int _x = 0;

  void _pushPoint(double? value) {
    if (value == null) return;
    if (_lightData.length >= 30) _lightData.removeAt(0);
    _lightData.add(FlSpot(_x.toDouble(), value));
    _x++;
  }

  Color _getLevelColor(double? light) {
    if (light == null) return Colors.grey;
    if (light < 200) return const Color(0xFF64B5F6);
    if (light < 800) return const Color(0xFFFFA726);
    return const Color(0xFFFFC107);
  }

  String _getLevelText(double? light) {
    if (light == null) return 'No data';
    if (light < 200) return 'Low';
    if (light < 800) return 'Medium';
    return 'High';
  }

  IconData _getLevelIcon(double? light) {
    if (light == null) return Icons.wb_sunny_outlined;
    if (light < 200) return Icons.nightlight_round;
    if (light < 800) return Icons.wb_cloudy;
    return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Light Detector'),
        centerTitle: true,
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
              final light = snapshot.data?.lightLevel;
              _pushPoint(light);

              if (snapshot.connectionState == ConnectionState.waiting &&
                  snapshot.data == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final color = _getLevelColor(light);
              final levelText = _getLevelText(light);
              final levelIcon = _getLevelIcon(light);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Current Light Level Card
                    GlassCard(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color.withOpacity(0.15),
                              boxShadow: [
                                BoxShadow(
                                  color: color.withOpacity(0.4),
                                  blurRadius: 30,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: Icon(levelIcon, size: 44, color: color),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Current Light Level',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white70,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            light != null
                                ? '${light.toStringAsFixed(0)} lux'
                                : '--',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: color,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: color.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              levelText,
                              style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Live Trend',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                    ),
                    const SizedBox(height: 12),

                    GlassCard(
                      child: SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            titlesData: FlTitlesData(
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              bottomTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  reservedSize: 44,
                                  getTitlesWidget: (value, meta) {
                                    return Text(
                                      value.toInt().toString(),
                                      style: const TextStyle(
                                        color: Colors.white38,
                                        fontSize: 10,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: 1000,
                              getDrawingHorizontalLine: (value) => FlLine(
                                color: Colors.white.withOpacity(0.05),
                                strokeWidth: 1,
                              ),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: _lightData.isEmpty
                                    ? [const FlSpot(0, 0)]
                                    : _lightData,
                                isCurved: true,
                                color: const Color(0xFFFFC107),
                                barWidth: 2.5,
                                dotData: const FlDotData(show: false),
                                belowBarData: BarAreaData(
                                  show: true,
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      const Color(0xFFFFC107).withOpacity(0.3),
                                      const Color(0xFFFFC107).withOpacity(0.0),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Text(
                      'Light Guide',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                    ),
                    const SizedBox(height: 12),

                    GlassCard(
                      child: Column(
                        children: [
                          _buildInfoRow(
                            Icons.nightlight_round,
                            'Low (<200 lux)',
                            'Shade or indoor conditions',
                            const Color(0xFF64B5F6),
                          ),
                          const Divider(height: 24, color: Colors.white12),
                          _buildInfoRow(
                            Icons.wb_cloudy,
                            'Medium (200\u2013800 lux)',
                            'Cloudy day or partial shade',
                            const Color(0xFFFFA726),
                          ),
                          const Divider(height: 24, color: Colors.white12),
                          _buildInfoRow(
                            Icons.wb_sunny,
                            'High (>800 lux)',
                            'Direct sunlight \u2014 ideal for most crops',
                            const Color(0xFFFFC107),
                          ),
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

  Widget _buildInfoRow(
      IconData icon, String label, String description, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
