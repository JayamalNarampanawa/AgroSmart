import 'package:flutter/material.dart';
import 'dart:async';

class IrrigationControlScreen extends StatefulWidget {
  const IrrigationControlScreen({super.key});

  @override
  State<IrrigationControlScreen> createState() => _IrrigationControlScreenState();
}

class _IrrigationControlScreenState extends State<IrrigationControlScreen> {
  bool isIrrigationActive = false;
  bool isAutoMode = true;
  double flowRate = 0.0; // L/min
  int duration = 0; // minutes
  Timer? _irrigationTimer;
  Timer? _updateTimer;

  @override
  void initState() {
    super.initState();
    _startDataUpdate();
  }

  @override
  void dispose() {
    _irrigationTimer?.cancel();
    _updateTimer?.cancel();
    super.dispose();
  }

  void _startDataUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (isIrrigationActive && mounted) {
        setState(() {
          flowRate = 2.5 + (DateTime.now().millisecond % 100) / 100;
          duration++;
        });
      }
    });
  }

  void _toggleIrrigation() {
    setState(() {
      isIrrigationActive = !isIrrigationActive;
      if (isIrrigationActive) {
        duration = 0;
        flowRate = 2.5;
      } else {
        flowRate = 0.0;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isIrrigationActive ? 'Irrigation started' : 'Irrigation stopped',
        ),
        backgroundColor: isIrrigationActive ? Colors.green : Colors.red,
      ),
    );
  }

  void _toggleAutoMode() {
    setState(() {
      isAutoMode = !isAutoMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Irrigation Control'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Control Panel
            Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Column(
                          children: [
                            Icon(
                              isIrrigationActive ? Icons.water : Icons.water_drop_outlined,
                              size: 48,
                              color: isIrrigationActive ? Colors.blue : Colors.grey,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              isIrrigationActive ? 'ACTIVE' : 'INACTIVE',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isIrrigationActive ? Colors.blue : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              flowRate.toStringAsFixed(1),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('L/min'),
                          ],
                        ),
                        Column(
                          children: [
                            Text(
                              '$duration',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('minutes'),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _toggleIrrigation,
                        icon: Icon(isIrrigationActive ? Icons.stop : Icons.play_arrow),
                        label: Text(
                          isIrrigationActive ? 'Stop Irrigation' : 'Start Irrigation',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isIrrigationActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Mode Control
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operation Mode',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Auto Mode'),
                      subtitle: Text(
                        isAutoMode 
                          ? 'System controls irrigation based on soil moisture'
                          : 'Manual control enabled',
                      ),
                      value: isAutoMode,
                      onChanged: (value) => _toggleAutoMode(),
                      activeThumbColor: Colors.green,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Schedule Settings
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Schedule Settings',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildScheduleItem('Morning', '06:00 AM', true),
                    _buildScheduleItem('Afternoon', '02:00 PM', false),
                    _buildScheduleItem('Evening', '06:00 PM', true),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // System Information
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'System Information',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildInfoRow('Pump Status', isIrrigationActive ? 'Running' : 'Stopped',
                        color: isIrrigationActive ? Colors.green : Colors.grey),
                    _buildInfoRow('Pressure', '2.3 Bar'),
                    _buildInfoRow('Total Runtime Today', '45 minutes'),
                    _buildInfoRow('Water Used Today', '112.5 L'),
                    _buildInfoRow('Next Scheduled', '06:00 PM'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleItem(String time, String schedule, bool isEnabled) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                time,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              Text(
                schedule,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          Switch(
            value: isEnabled,
            onChanged: (value) {
              // Handle schedule toggle
            },
            activeThumbColor: Colors.green,
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