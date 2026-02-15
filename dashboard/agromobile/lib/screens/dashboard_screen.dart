import 'package:flutter/material.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Mock sensor data
  double soilMoisture = 65.0;
  bool irrigationActive = false;
  double waterLevel = 78.0;
  String lightIntensity = 'Medium';
  bool securityActive = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Agri-Bot Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Simulate data refresh
                soilMoisture = (soilMoisture + 5) % 100;
                waterLevel = (waterLevel + 3) % 100;
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Overview
            const Text(
              'System Status',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Status Cards Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildStatusCard(
                  'Soil Moisture',
                  '${soilMoisture.toInt()}%',
                  Icons.water_drop,
                  Colors.blue,
                ),
                _buildStatusCard(
                  'Water Level',
                  '${waterLevel.toInt()}%',
                  Icons.local_drink,
                  Colors.cyan,
                ),
                _buildStatusCard(
                  'Light Level',
                  lightIntensity,
                  Icons.wb_sunny,
                  Colors.orange,
                ),
                _buildStatusCard(
                  'Security',
                  securityActive ? 'Active' : 'Inactive',
                  Icons.security,
                  securityActive ? Colors.green : Colors.red,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      setState(() {
                        irrigationActive = !irrigationActive;
                      });
                    },
                    icon: Icon(irrigationActive ? Icons.stop : Icons.play_arrow),
                    label: Text(irrigationActive ? 'Stop Irrigation' : 'Start Irrigation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: irrigationActive ? Colors.red : Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // System Health Indicators
            const Text(
              'System Health',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildHealthIndicator('Sensors', true),
                    _buildHealthIndicator('Connectivity', true),
                    _buildHealthIndicator('Power Supply', true),
                    _buildHealthIndicator('Water Pump', irrigationActive),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthIndicator(String component, bool isHealthy) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(component),
          Row(
            children: [
              Icon(
                isHealthy ? Icons.check_circle : Icons.error,
                color: isHealthy ? Colors.green : Colors.red,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                isHealthy ? 'Online' : 'Offline',
                style: TextStyle(
                  color: isHealthy ? Colors.green : Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}