import 'package:flutter/material.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'dart:async';
import 'dart:math';

class WaterLevelScreen extends StatefulWidget {
  const WaterLevelScreen({super.key});

  @override
  State<WaterLevelScreen> createState() => _WaterLevelScreenState();
}

class _WaterLevelScreenState extends State<WaterLevelScreen> {
  double waterLevel = 78.0; // Percentage
  double tankCapacity = 1000.0; // Liters
  double currentVolume = 780.0; // Liters
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
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      setState(() {
        // Simulate water level changes
        waterLevel += (_random.nextDouble() - 0.5) * 3;
        waterLevel = waterLevel.clamp(0.0, 100.0);
        currentVolume = (waterLevel / 100) * tankCapacity;
      });
    });
  }

  Color _getWaterLevelColor() {
    if (waterLevel < 20) return Colors.red;
    if (waterLevel < 50) return Colors.orange;
    return Colors.blue;
  }

  String _getWaterLevelStatus() {
    if (waterLevel < 20) return 'Critical - Refill Required';
    if (waterLevel < 50) return 'Low - Monitor Closely';
    return 'Good';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Water Level Monitor'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Main Water Level Display
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    const Text(
                      'Water Tank Level',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    
                    // Water Tank Visual
                    Container(
                      width: 120,
                      height: 200,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey, width: 3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          // Water fill
                          Container(
                            width: double.infinity,
                            height: (waterLevel / 100) * 200,
                            decoration: BoxDecoration(
                              color: _getWaterLevelColor().withValues(alpha: 0.7),
                              borderRadius: const BorderRadius.only(
                                bottomLeft: Radius.circular(5),
                                bottomRight: Radius.circular(5),
                              ),
                            ),
                          ),
                          // Level indicator
                          Positioned(
                            right: -30,
                            bottom: (waterLevel / 100) * 200 - 10,
                            child: Row(
                              children: [
                                Container(
                                  width: 20,
                                  height: 2,
                                  color: _getWaterLevelColor(),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${waterLevel.toInt()}%',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: _getWaterLevelColor(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Volume Display
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Text(
                              '${currentVolume.toInt()}L',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Current'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '${tankCapacity.toInt()}L',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Capacity'),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      _getWaterLevelStatus(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: _getWaterLevelColor(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Linear Progress Bar
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Water Level Progress',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    LinearPercentIndicator(
                      lineHeight: 20.0,
                      percent: waterLevel / 100,
                      center: Text(
                        '${waterLevel.toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      progressColor: _getWaterLevelColor(),
                      backgroundColor: Colors.grey.withValues(alpha: 0.3),
                      barRadius: const Radius.circular(10),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Water Level Alerts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Alert Thresholds',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildAlertThreshold('Critical Level', '< 20%', Colors.red),
                    _buildAlertThreshold('Low Level', '20% - 50%', Colors.orange),
                    _buildAlertThreshold('Normal Level', '> 50%', Colors.blue),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Tank Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tank Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Tank Type', 'Polyethylene'),
                    _buildInfoRow('Capacity', '${tankCapacity.toInt()} L'),
                    _buildInfoRow('Current Volume', '${currentVolume.toInt()} L'),
                    _buildInfoRow('Remaining', '${(tankCapacity - currentVolume).toInt()} L'),
                    _buildInfoRow('Location', 'Rooftop - North Side'),
                    _buildInfoRow('Sensor Type', 'Ultrasonic Level Sensor'),
                    _buildInfoRow('Last Refill', '3 days ago'),
                    _buildInfoRow('Status', 'Active', color: Colors.green),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Refill Button
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tank Management',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: waterLevel < 90 ? () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Refill process initiated'),
                                  backgroundColor: Colors.blue,
                                ),
                              );
                            } : null,
                            icon: const Icon(Icons.water),
                            label: const Text('Start Refill'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Drain valve opened'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                            icon: const Icon(Icons.water_drop),
                            label: const Text('Drain Tank'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertThreshold(String level, String range, Color color) {
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
                  level,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  range,
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
