import 'package:flutter/material.dart';
import '../widgets/glass_card.dart';

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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Dashboard'),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF050A14),
              const Color(0xFF0B1221),
              const Color(0xFF050A14),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Section
                Text(
                  'System Status',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Real-time monitoring',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                ),
                const SizedBox(height: 24),

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
                      'Soil Moisture',
                      '${soilMoisture.toInt()}%',
                      Icons.water_drop,
                      const Color(0xFF00E5FF),
                      soilMoisture / 100,
                    ),
                    _buildStatusCard(
                      'Water Level',
                      '${waterLevel.toInt()}%',
                      Icons.local_drink,
                      const Color(0xFF00FFC2),
                      waterLevel / 100,
                    ),
                    _buildStatusCard(
                      'Light Level',
                      lightIntensity,
                      Icons.wb_sunny,
                      const Color(0xFFFFC107),
                      0.6,
                    ),
                    _buildStatusCard(
                      'Security',
                      securityActive ? 'Active' : 'Inactive',
                      Icons.security,
                      securityActive
                          ? const Color(0xFF00FFC2)
                          : const Color(0xFFFF5252),
                      securityActive ? 1.0 : 0.0,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Quick Actions
                Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  padding: const EdgeInsets.all(0),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        setState(() {
                          irrigationActive = !irrigationActive;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (irrigationActive
                                        ? const Color(0xFFFF5252)
                                        : const Color(0xFF00FFC2))
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                irrigationActive
                                    ? Icons.stop
                                    : Icons.play_arrow,
                                color: irrigationActive
                                    ? const Color(0xFFFF5252)
                                    : const Color(0xFF00FFC2),
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    irrigationActive
                                        ? 'Stop Irrigation'
                                        : 'Start Irrigation',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    irrigationActive
                                        ? 'System is running'
                                        : 'Tap to activate',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.white.withOpacity(0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color: Colors.white.withOpacity(0.4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // System Health Indicators
                Text(
                  'System Health',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 16),

                GlassCard(
                  child: Column(
                    children: [
                      _buildHealthIndicator('Sensors', true),
                      const Divider(height: 24, color: Colors.white12),
                      _buildHealthIndicator('Connectivity', true),
                      const Divider(height: 24, color: Colors.white12),
                      _buildHealthIndicator('Power Supply', true),
                      const Divider(height: 24, color: Colors.white12),
                      _buildHealthIndicator('Water Pump', irrigationActive),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
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
