import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'dart:math';

class LightDetectorScreen extends StatefulWidget {
  const LightDetectorScreen({super.key});

  @override
  State<LightDetectorScreen> createState() => _LightDetectorScreenState();
}

class _LightDetectorScreenState extends State<LightDetectorScreen> {
  double lightIntensity = 750.0; // Lux
  String lightLevel = 'Medium';
  Timer? _timer;
  final Random _random = Random();
  List<FlSpot> lightData = [];

  @override
  void initState() {
    super.initState();
    _initializeData();
    _startMockDataUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initializeData() {
    // Initialize with some sample data points
    for (int i = 0; i < 10; i++) {
      lightData.add(FlSpot(i.toDouble(), 500 + _random.nextDouble() * 500));
    }
  }

  void _startMockDataUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      setState(() {
        // Simulate light intensity changes
        lightIntensity += (_random.nextDouble() - 0.5) * 200;
        lightIntensity = lightIntensity.clamp(0.0, 1500.0);
        
        _updateLightLevel();
        _updateChart();
      });
    });
  }

  void _updateLightLevel() {
    if (lightIntensity < 200) {
      lightLevel = 'Low';
    } else if (lightIntensity < 800) {
      lightLevel = 'Medium';
    } else {
      lightLevel = 'High';
    }
  }

  void _updateChart() {
    if (lightData.length >= 20) {
      lightData.removeAt(0);
    }
    
    // Shift x values
    for (int i = 0; i < lightData.length; i++) {
      lightData[i] = FlSpot(i.toDouble(), lightData[i].y);
    }
    
    lightData.add(FlSpot(lightData.length.toDouble(), lightIntensity));
  }

  Color _getLightColor() {
    if (lightIntensity < 200) return Colors.blue;
    if (lightIntensity < 800) return Colors.orange;
    return Colors.yellow;
  }

  IconData _getLightIcon() {
    if (lightIntensity < 200) return Icons.nightlight;
    if (lightIntensity < 800) return Icons.wb_cloudy;
    return Icons.wb_sunny;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Light Detector'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Current Light Level Display
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      _getLightIcon(),
                      size: 64,
                      color: _getLightColor(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '${lightIntensity.toInt()} Lux',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: _getLightColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      lightLevel,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: _getLightColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Light Intensity Chart
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Light Intensity Over Time',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: const FlGridData(show: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  return Text('${value.toInt()}');
                                },
                              ),
                            ),
                            bottomTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                          ),
                          borderData: FlBorderData(show: true),
                          lineBarsData: [
                            LineChartBarData(
                              spots: lightData,
                              isCurved: true,
                              color: Colors.orange,
                              barWidth: 3,
                              dotData: const FlDotData(show: false),
                            ),
                          ],
                          minY: 0,
                          maxY: 1500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Light Level Guide
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Light Level Guide',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildLightRange('0-200 Lux', 'Low Light - Night/Indoor', Colors.blue),
                    _buildLightRange('200-800 Lux', 'Medium Light - Cloudy Day', Colors.orange),
                    _buildLightRange('800+ Lux', 'High Light - Sunny Day', Colors.yellow),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Sensor Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sensor Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Sensor Type', 'BH1750 Light Sensor'),
                    _buildInfoRow('Range', '0-65535 Lux'),
                    _buildInfoRow('Accuracy', '±20%'),
                    _buildInfoRow('Location', 'Field Center'),
                    _buildInfoRow('Last Update', 'Just now'),
                    _buildInfoRow('Status', 'Active', color: Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLightRange(String range, String description, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  range,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}