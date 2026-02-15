import 'package:flutter/material.dart';
import 'dart:async';

class SecurityAlarmScreen extends StatefulWidget {
  const SecurityAlarmScreen({super.key});

  @override
  State<SecurityAlarmScreen> createState() => _SecurityAlarmScreenState();
}

class _SecurityAlarmScreenState extends State<SecurityAlarmScreen> {
  bool isAlarmActive = true;
  bool isAlarmTriggered = false;
  String lastAlert = 'No recent alerts';
  Timer? _alertTimer;
  List<Map<String, dynamic>> alertHistory = [
    {
      'time': '2 hours ago',
      'type': 'Motion Detected',
      'location': 'Field Perimeter - North',
      'severity': 'Medium',
      'resolved': true,
    },
    {
      'time': '1 day ago',
      'type': 'Unauthorized Access',
      'location': 'Equipment Shed',
      'severity': 'High',
      'resolved': true,
    },
    {
      'time': '3 days ago',
      'type': 'Fence Breach',
      'location': 'Field Perimeter - East',
      'severity': 'High',
      'resolved': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _simulateRandomAlerts();
  }

  @override
  void dispose() {
    _alertTimer?.cancel();
    super.dispose();
  }

  void _simulateRandomAlerts() {
    _alertTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (isAlarmActive && DateTime.now().second % 20 == 0) {
        _triggerAlert();
      }
    });
  }

  void _triggerAlert() {
    if (mounted) {
      setState(() {
        isAlarmTriggered = true;
        lastAlert = 'Motion detected - ${DateTime.now().toString().substring(11, 19)}';
      });

      // Auto-resolve after 10 seconds
      Timer(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            isAlarmTriggered = false;
          });
        }
      });
    }
  }

  void _toggleAlarmSystem() {
    setState(() {
      isAlarmActive = !isAlarmActive;
      if (!isAlarmActive) {
        isAlarmTriggered = false;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isAlarmActive ? 'Security system activated' : 'Security system deactivated',
        ),
        backgroundColor: isAlarmActive ? Colors.green : Colors.red,
      ),
    );
  }

  void _acknowledgeAlert() {
    setState(() {
      isAlarmTriggered = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert acknowledged'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getStatusColor() {
    if (!isAlarmActive) return Colors.grey;
    if (isAlarmTriggered) return Colors.red;
    return Colors.green;
  }

  String _getStatusText() {
    if (!isAlarmActive) return 'DISABLED';
    if (isAlarmTriggered) return 'ALERT';
    return 'ARMED';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Security Alarm'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Security Status Display
            Card(
              elevation: 8,
              color: isAlarmTriggered ? Colors.red.withValues(alpha: 0.1) : null,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      isAlarmTriggered 
                        ? Icons.warning 
                        : isAlarmActive 
                          ? Icons.security 
                          : Icons.security_outlined,
                      size: 64,
                      color: _getStatusColor(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _getStatusText(),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isAlarmTriggered 
                        ? 'SECURITY BREACH DETECTED'
                        : isAlarmActive 
                          ? 'System monitoring active'
                          : 'System disabled',
                      style: TextStyle(
                        fontSize: 14,
                        color: _getStatusColor(),
                      ),
                    ),
                    if (isAlarmTriggered) ...[
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _acknowledgeAlert,
                        icon: const Icon(Icons.check),
                        label: const Text('Acknowledge Alert'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Control Panel
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Control',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _toggleAlarmSystem,
                        icon: Icon(isAlarmActive ? Icons.security_outlined : Icons.security),
                        label: Text(
                          isAlarmActive ? 'Disable Security' : 'Enable Security',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAlarmActive ? Colors.red : Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Security Zones
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Security Zones',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    _buildSecurityZone('Field Perimeter', true, 'Motion Sensors'),
                    _buildSecurityZone('Equipment Shed', true, 'Door Sensor'),
                    _buildSecurityZone('Water Tank Area', true, 'Camera + Motion'),
                    _buildSecurityZone('Main Gate', false, 'Access Control'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Recent Alerts
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Recent Alerts',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    if (alertHistory.isEmpty)
                      const Center(
                        child: Text(
                          'No recent alerts',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    else
                      ...alertHistory.map((alert) => _buildAlertItem(alert)),
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
                    _buildInfoRow('System Status', _getStatusText(), 
                        color: _getStatusColor()),
                    _buildInfoRow('Active Sensors', '8 of 8'),
                    _buildInfoRow('Last System Check', '5 minutes ago'),
                    _buildInfoRow('Battery Backup', '98%'),
                    _buildInfoRow('Network Connection', 'Strong'),
                    _buildInfoRow('Last Alert', lastAlert),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityZone(String name, bool isActive, String sensorType) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.error,
            color: isActive ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  sensorType,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          Text(
            isActive ? 'Active' : 'Offline',
            style: TextStyle(
              color: isActive ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(Map<String, dynamic> alert) {
    Color severityColor = alert['severity'] == 'High' 
        ? Colors.red 
        : alert['severity'] == 'Medium' 
          ? Colors.orange 
          : Colors.yellow;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: alert['resolved'] ? Colors.grey : severityColor,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['type'],
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${alert['location']} â€¢ ${alert['time']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
          if (alert['resolved'])
            const Icon(
              Icons.check_circle_outline,
              color: Colors.green,
              size: 16,
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
