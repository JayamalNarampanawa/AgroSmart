import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'dart:math';

class SoilMoistureScreen extends StatefulWidget {
  const SoilMoistureScreen({super.key});

  @override
  State<SoilMoistureScreen> createState() => _SoilMoistureScreenState();
}

class _SoilMoistureScreenState extends State<SoilMoistureScreen> {
  double moistureLevel = 65.0;
  Timer? _timer;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _startMockDataUpdate();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startMockDataUpdate() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      setState(() {
        // Simulate realistic moisture changes
        moistureLevel += (_random.nextDouble() - 0.5) * 4;
        moistureLevel = moistureLevel.clamp(0.0, 100.0);
      });
    });
  }

  Color _getMoistureColor() {
    if (moistureLevel < 30) return Colors.red;
    if (moistureLevel < 60) return Colors.orange;
    return Colors.green;
  }

  String _getMoistureStatus() {
    if (moistureLevel < 30) return 'Low - Irrigation Needed';
    if (moistureLevel < 60) return 'Moderate';
    return 'Optimal';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Soil Moisture Monitor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Moisture Display
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Current Soil Moisture',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Circular Progress Indicator
                    CircularPercentIndicator(
                      radius: 80.0,
                      lineWidth: 12.0,
                      percent: moistureLevel / 100,
                      center: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${moistureLevel.toInt()}%',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Text(
                            'Moisture',
                            style: TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      progressColor: _getMoistureColor(),
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      circularStrokeCap: CircularStrokeCap.round,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      _getMoistureStatus(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getMoistureColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Moisture Level Ranges
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Moisture Level Guide',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildMoistureRange('0-30%', 'Low - Irrigation Required', Colors.red),
                    _buildMoistureRange('30-60%', 'Moderate - Monitor Closely', Colors.orange),
                    _buildMoistureRange('60-100%', 'Optimal - Good Condition', Colors.green),
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
                    _buildInfoRow('Sensor Type', 'Capacitive Soil Moisture'),
                    _buildInfoRow('Location', 'Field Zone A'),
                    _buildInfoRow('Depth', '15 cm'),
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

  Widget _buildMoistureRange(String range, String description, Color color) {
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
