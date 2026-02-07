import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../models/analytics_point.dart';
import '../models/farm_profile.dart';
import '../models/sensor_data.dart';
import '../services/alert_service.dart';
import '../services/firebase_service.dart';
import '../widgets/alerts_panel.dart';
import '../widgets/charts.dart';
import '../widgets/glass_card.dart';
import '../widgets/gradient_background.dart';
import '../widgets/insights_panel.dart';
import '../widgets/kpi_card.dart';
import '../widgets/section_header.dart';
import '../widgets/sensor_card.dart';
import '../widgets/soil_profile_form.dart';
import '../widgets/status_pill.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: StreamBuilder<SensorData?>(
          stream: FirebaseService.instance.currentDataStream(),
          builder: (context, snapshot) {
            final current = snapshot.data;
            if (current != null) {
              AlertService.instance.checkAndNotify(current);
            }
            return StreamBuilder<List<AnalyticsPoint>>(
              stream: FirebaseService.instance.analyticsStream(),
              builder: (context, analyticsSnap) {
                final points = analyticsSnap.data ?? <AnalyticsPoint>[];
                return StreamBuilder<FarmProfile>(
                  stream: FirebaseService.instance.farmProfileStream(),
                  builder: (context, farmSnap) {
                    final profile = farmSnap.data ?? FarmProfile.fromMap(null);
                    return ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                      children: [
                        _buildHeader(context, current),
                        const SizedBox(height: 20),
                        SectionHeader(
                          eyebrow: 'Live Monitoring',
                          title: 'Current Sensor Readings',
                          subtitle: 'Real-time environmental data from your farm',
                          trailing: const StatusPill(label: 'Live', color: Color(0xFF22D3EE)),
                        ),
                        const SizedBox(height: 16),
                        _buildSensorGrid(context, current),
                        const SizedBox(height: 20),
                        SectionHeader(
                          eyebrow: 'Overview',
                          title: 'KPI Metrics',
                          subtitle: 'High, low, and total readings',
                        ),
                        const SizedBox(height: 12),
                        _buildKpis(points),
                        const SizedBox(height: 20),
                        SectionHeader(
                          eyebrow: 'Alerts',
                          title: 'Notifications & Insights',
                          subtitle: 'Immediate actions based on thresholds',
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: GlassCard(
                                          child: AlertsPanel(current: current),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: GlassCard(
                                          child: InsightsPanel(current: current),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      GlassCard(child: AlertsPanel(current: current)),
                                      const SizedBox(height: 14),
                                      GlassCard(child: InsightsPanel(current: current)),
                                    ],
                                  );
                          },
                        ),
                        const SizedBox(height: 20),
                        SectionHeader(
                          eyebrow: 'Analytics',
                          title: 'Historical Analysis',
                          subtitle: 'Trends and irrigation activity',
                        ),
                        const SizedBox(height: 12),
                        GlassCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Temperature & Humidity', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              SizedBox(height: 220, child: TemperatureHumidityChart(points: points)),
                              const SizedBox(height: 16),
                              const Text('Soil Moisture vs Ideal Range', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              SizedBox(height: 200, child: SoilMoistureChart(points: points)),
                              const SizedBox(height: 16),
                              const Text('Irrigation Activity', style: TextStyle(fontWeight: FontWeight.w600)),
                              const SizedBox(height: 12),
                              SizedBox(height: 160, child: PumpActivityChart(points: points)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        SectionHeader(
                          eyebrow: 'Soil Management',
                          title: 'Soil Profile',
                          subtitle: 'NPK values and pH inputs',
                        ),
                        const SizedBox(height: 12),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 900;
                            return isWide
                                ? Row(
                                    children: [
                                      Expanded(
                                        child: GlassCard(
                                          child: SoilProfileForm(
                                            profile: profile,
                                            onSave: (updated) => FirebaseService.instance.updateFarmProfile(updated),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: GlassCard(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text('Soil Condition', style: TextStyle(fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 12),
                                              SizedBox(height: 180, child: MoistureStatusPie(soilMoisture: current?.soilMoisture)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Column(
                                    children: [
                                      GlassCard(
                                        child: SoilProfileForm(
                                          profile: profile,
                                          onSave: (updated) => FirebaseService.instance.updateFarmProfile(updated),
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      GlassCard(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text('Soil Condition', style: TextStyle(fontWeight: FontWeight.w600)),
                                            const SizedBox(height: 12),
                                            SizedBox(height: 180, child: MoistureStatusPie(soilMoisture: current?.soilMoisture)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, SensorData? current) {
    final pumpLabel = current?.pumpStatus == true ? 'Pump: ON' : 'Pump: OFF';
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AgroSmart Dashboard',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              pumpLabel,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white60),
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: Colors.white.withOpacity(0.08),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(color: Color(0xFF22D3EE), shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              const Text('LIVE', style: TextStyle(letterSpacing: 1.4, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorGrid(BuildContext context, SensorData? current) {
    final temp = current?.temperature;
    final humidity = current?.humidity;
    final soil = current?.soilMoisture;
    final light = current?.lightLevel;

    final tempVisual = _temperatureVisual(temp);
    final humidityVisual = _humidityVisual(humidity);
    final soilVisual = _soilVisual(soil);
    final lightVisual = _lightVisual(light);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cards = [
          SensorCard(
            title: 'Temperature',
            value: temp?.toStringAsFixed(1) ?? '--',
            unit: '°C',
            icon: FontAwesomeIcons.temperatureHalf,
            accent: tempVisual.color,
            status: tempVisual.status,
          ),
          SensorCard(
            title: 'Humidity',
            value: humidity?.toStringAsFixed(1) ?? '--',
            unit: '%',
            icon: FontAwesomeIcons.cloudRain,
            accent: humidityVisual.color,
            status: humidityVisual.status,
          ),
          SensorCard(
            title: 'Soil Moisture',
            value: soil?.toStringAsFixed(0) ?? '--',
            unit: '',
            icon: FontAwesomeIcons.seedling,
            accent: soilVisual.color,
            status: soilVisual.status,
            progress: soil == null ? null : (soil / 4095),
          ),
          SensorCard(
            title: 'Light Level',
            value: light?.toStringAsFixed(0) ?? '--',
            unit: ' lux',
            icon: FontAwesomeIcons.solidSun,
            accent: lightVisual.color,
            status: lightVisual.status,
          ),
        ];

        if (isWide) {
          return Row(
            children: List.generate(cards.length, (index) {
              final card = cards[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == cards.length - 1 ? 0 : 12),
                  child: SizedBox(height: 180, child: card),
                ),
              );
            }),
          );
        }

        return Column(
          children: cards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SizedBox(height: 180, child: card),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildKpis(List<AnalyticsPoint> points) {
    if (points.isEmpty) {
      return const Text('No KPI data available yet', style: TextStyle(color: Colors.white60));
    }
    double? highTemp;
    double? lowTemp;
    double? highHumidity;
    double? lowHumidity;
    for (final point in points) {
      if (point.temperature != null) {
        highTemp = highTemp == null ? point.temperature : (point.temperature! > highTemp ? point.temperature : highTemp);
        lowTemp = lowTemp == null ? point.temperature : (point.temperature! < lowTemp ? point.temperature : lowTemp);
      }
      if (point.humidity != null) {
        highHumidity = highHumidity == null ? point.humidity : (point.humidity! > highHumidity ? point.humidity : highHumidity);
        lowHumidity = lowHumidity == null ? point.humidity : (point.humidity! < lowHumidity ? point.humidity : lowHumidity);
      }
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cards = [
          KpiCard(label: 'Total Records', value: points.length.toString(), accent: const Color(0xFF38BDF8)),
          KpiCard(label: 'High Temp', value: highTemp?.toStringAsFixed(1) ?? '--', accent: const Color(0xFFFB7185)),
          KpiCard(label: 'Low Temp', value: lowTemp?.toStringAsFixed(1) ?? '--', accent: const Color(0xFF0EA5E9)),
          KpiCard(label: 'High Humidity', value: highHumidity?.toStringAsFixed(1) ?? '--', accent: const Color(0xFF22D3EE)),
          KpiCard(label: 'Low Humidity', value: lowHumidity?.toStringAsFixed(1) ?? '--', accent: const Color(0xFF10B981)),
        ];

        if (isWide) {
          return Row(
            children: List.generate(cards.length, (index) {
              final card = cards[index];
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == cards.length - 1 ? 0 : 10),
                  child: card,
                ),
              );
            }),
          );
        }

        return Column(
          children: cards
              .map((card) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: card,
                  ))
              .toList(),
        );
      },
    );
  }
}

class _Visual {
  final Color color;
  final String status;

  const _Visual(this.color, this.status);
}

_Visual _temperatureVisual(double? value) {
  if (value == null) return const _Visual(Color(0xFF94A3B8), '--');
  if (value > 30) return const _Visual(Color(0xFFEF4444), 'Hot');
  if (value < 15) return const _Visual(Color(0xFF0EA5E9), 'Cold');
  return const _Visual(Color(0xFF10B981), 'Normal');
}

_Visual _humidityVisual(double? value) {
  if (value == null) return const _Visual(Color(0xFF94A3B8), '--');
  if (value < 30) return const _Visual(Color(0xFFF59E0B), 'Low');
  if (value > 60) return const _Visual(Color(0xFF0EA5E9), 'High');
  return const _Visual(Color(0xFF06B6D4), 'Normal');
}

_Visual _soilVisual(double? value) {
  if (value == null) return const _Visual(Color(0xFF94A3B8), '--');
  if (value > 2200) return const _Visual(Color(0xFFF97316), 'Dry');
  if (value > 1200) return const _Visual(Color(0xFF10B981), 'Optimal');
  return const _Visual(Color(0xFF0EA5E9), 'Wet');
}

_Visual _lightVisual(double? value) {
  if (value == null) return const _Visual(Color(0xFF94A3B8), '--');
  if (value < 200) return const _Visual(Color(0xFFFBBF24), 'Bright');
  if (value > 2000) return const _Visual(Color(0xFF94A3B8), 'Dark');
  return const _Visual(Color(0xFFFFD166), 'Normal');
}
