import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/auth_service.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/health_card.dart';
import '../widgets/cards/insight_card.dart';
import '../widgets/cards/sensor_metric_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/charts/premium_doughnut_chart.dart';
import '../widgets/charts/premium_line_chart.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/skeleton_loader.dart';
import '../widgets/common/status_badge.dart';
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
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<SensorData?>(
        stream: FirebaseService.instance.currentDataStream(),
        initialData: FirebaseService.instance.latestSensorData,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final soil = data?.soilMoisture;
          final humidity = data?.humidity;
          final light = data?.lightLevel;
          final pumpOn = data?.pumpStatus ?? false;
          final temp = data?.temperature;
          final isConnected =
              snapshot.connectionState == ConnectionState.active;
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  data == null;

          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            color: AppColors.primary,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl,
                AppSpacing.md,
                AppSpacing.xl,
                AppSpacing.sectionLarge,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: AuthService.instance.sessionEmail,
                    builder: (context, email, _) {
                      final label = email?.split('@').first.trim();
                      final avatarText =
                          (label == null || label.isEmpty) ? 'A' : label[0];
                      return DashboardHeader(
                        leading: const SizedBox(width: 36, height: 44),
                        greeting: 'Good day, ${label ?? 'AgroSmart'}',
                        subtitle:
                            '${DateFormat('EEE, MMM d').format(DateTime.now())} - Live farm command center',
                        avatarText: avatarText,
                        trailing: _HeaderIconButton(
                          icon: Icons.refresh_rounded,
                          onPressed: _refresh,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Align(
                    alignment: Alignment.centerRight,
                    child: _HeaderIconFrame(child: NotificationButton()),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  if (isLoading) ...[
                    const SkeletonCard(),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  if (snapshot.hasError) ...[
                    AlertCard(
                      icon: Icons.cloud_off_rounded,
                      title: 'Live data unavailable',
                      message: 'Firebase returned: ${snapshot.error}',
                      color: AppColors.accentRose,
                      tone: StatusBadgeTone.error,
                      timestamp: 'Error',
                    ),
                    const SizedBox(height: AppSpacing.section),
                  ],
                  _DashboardHero(
                    temp: temp,
                    humidity: humidity,
                    soil: soil,
                    light: light,
                    pumpOn: pumpOn,
                    isConnected: isConnected,
                  ),
                  const SizedBox(height: AppSpacing.sectionLarge),
                  SectionHeader(
                    title: 'Live Sensors',
                    subtitle: 'Current readings from the greenhouse node',
                    actionText: isConnected ? 'Live' : 'Offline',
                    actionIcon: isConnected
                        ? Icons.wifi_tethering_rounded
                        : Icons.wifi_off_rounded,
                    onAction: _refresh,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  _SensorList(
                    temp: temp,
                    humidity: humidity,
                    soil: soil,
                    light: light,
                  ),
                  const SizedBox(height: AppSpacing.sectionLarge),
                  const SectionHeader(
                    title: 'Environment Balance',
                    subtitle: 'Normalized view of the current sensor snapshot',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SoftWhiteCard(
                    child: SizedBox(
                      height: 210,
                      child: PremiumLineChart(
                        values: _signalValues(temp, humidity, soil, light),
                        color: AppColors.primary,
                        minY: 0,
                        maxY: 100,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.section),
                  Row(
                    children: [
                      Expanded(
                        child: SoftWhiteCard(
                          title: 'Soil Index',
                          subtitle: _soilStatus(soil),
                          child: SizedBox(
                            height: 150,
                            child: PremiumDoughnutChart(
                              value: _progress(soil, 0, 3000),
                              centerLabel:
                                  '${(_progress(soil, 0, 3000) * 100).round()}%',
                              color: AppColors.accentGreen,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: SoftWhiteCard(
                          title: 'Pump State',
                          subtitle: pumpOn ? 'Water flow active' : 'Ready',
                          child: SizedBox(
                            height: 150,
                            child: PremiumDoughnutChart(
                              value: pumpOn ? 1 : 0.18,
                              centerLabel: pumpOn ? 'On' : 'Off',
                              color: pumpOn
                                  ? AppColors.accentCyan
                                  : AppColors.accentOrange,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sectionLarge),
                  const SectionHeader(
                    title: 'System Health',
                    subtitle: 'Device, connectivity and control status',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  StreamBuilder<bool>(
                    stream: FirebaseService.instance.realtimeConnectionStream(),
                    initialData: data != null,
                    builder: (context, connectionSnapshot) {
                      final databaseOnline = connectionSnapshot.data == true;

                      return SoftWhiteCard(
                        child: Column(
                          children: [
                            HealthCard(
                              title: 'Sensor Node',
                              status: data != null ? 'Online' : 'Offline',
                              icon: Icons.sensors_rounded,
                              tone: data != null
                                  ? StatusBadgeTone.success
                                  : StatusBadgeTone.error,
                              pulse: data == null,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            HealthCard(
                              title: 'Realtime Database',
                              status: databaseOnline ? 'Connected' : 'Syncing',
                              icon: databaseOnline
                                  ? Icons.cloud_done_rounded
                                  : Icons.cloud_sync_rounded,
                              tone: databaseOnline
                                  ? StatusBadgeTone.success
                                  : StatusBadgeTone.warning,
                              pulse: !databaseOnline,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            const HealthCard(
                              title: 'Power Supply',
                              status: 'Stable',
                              icon: Icons.battery_charging_full_rounded,
                              tone: StatusBadgeTone.success,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            HealthCard(
                              title: 'Water Pump',
                              status: pumpOn ? 'Running' : 'Standby',
                              icon: Icons.water_drop_rounded,
                              tone: pumpOn
                                  ? StatusBadgeTone.info
                                  : StatusBadgeTone.neutral,
                              pulse: pumpOn,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sectionLarge),
                  const SectionHeader(
                    title: 'Smart Insights',
                    subtitle: 'Quick actions based on the live snapshot',
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  ..._insightCards(temp, humidity, soil, light, pumpOn).expand(
                    (widget) => [
                      widget,
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _insightCards(
    double? temp,
    double? humidity,
    double? soil,
    double? light,
    bool pumpOn,
  ) {
    final cards = <Widget>[];

    if (soil == null && temp == null && humidity == null && light == null) {
      return [
        const InsightCard(
          icon: Icons.info_outline_rounded,
          title: 'Waiting for farm data',
          subtitle:
              'The dashboard will update as soon as Firebase receives a sensor snapshot.',
          badge: 'Pending',
          tone: StatusBadgeTone.warning,
          color: AppColors.accentOrange,
        ),
      ];
    }

    cards.add(
      InsightCard(
        icon: soil != null && soil > 2200
            ? Icons.water_drop_outlined
            : Icons.eco_rounded,
        title: soil != null && soil > 2200
            ? 'Irrigation attention'
            : 'Soil looks balanced',
        subtitle: soil != null && soil > 2200
            ? 'Soil moisture is trending dry. Review the irrigation schedule before crop stress rises.'
            : 'Moisture is inside the expected operating band for the current profile.',
        badge: soil != null && soil > 2200 ? 'Action' : 'Healthy',
        tone: soil != null && soil > 2200
            ? StatusBadgeTone.warning
            : StatusBadgeTone.success,
        color: soil != null && soil > 2200
            ? AppColors.accentOrange
            : AppColors.accentGreen,
      ),
    );

    cards.add(
      InsightCard(
        icon: temp != null && temp > 34
            ? Icons.device_thermostat_rounded
            : Icons.auto_graph_rounded,
        title: temp != null && temp > 34 ? 'Heat watch' : 'Climate stable',
        subtitle: temp != null && temp > 34
            ? 'Temperature is above the comfort band. Increase ventilation if this reading continues.'
            : 'Temperature and humidity are in a normal monitoring state.',
        badge: temp != null && temp > 34 ? 'Warning' : 'Stable',
        tone: temp != null && temp > 34
            ? StatusBadgeTone.warning
            : StatusBadgeTone.info,
        color: temp != null && temp > 34
            ? AppColors.accentRose
            : AppColors.primary,
      ),
    );

    cards.add(
      InsightCard(
        icon: pumpOn ? Icons.opacity_rounded : Icons.task_alt_rounded,
        title: pumpOn ? 'Pump is active' : 'Pump on standby',
        subtitle: pumpOn
            ? 'Water delivery is currently running. Monitor moisture response over the next cycle.'
            : 'No active irrigation cycle is running right now.',
        badge: pumpOn ? 'Running' : 'Ready',
        tone: pumpOn ? StatusBadgeTone.info : StatusBadgeTone.neutral,
        color: pumpOn ? AppColors.accentCyan : AppColors.textSecondary,
      ),
    );

    return cards;
  }

  static double _progress(double? value, double min, double max) {
    if (value == null || max <= min) return 0;
    final clamped = value.clamp(min, max);
    return (clamped - min) / (max - min);
  }

  static String _format(double? value, String unit, {int decimals = 1}) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(decimals)}$unit';
  }

  static String _soilStatus(double? soil) {
    if (soil == null) return 'No moisture reading';
    if (soil > 2200) return 'Dry range';
    if (soil < 1200) return 'Wet range';
    return 'Optimal range';
  }

  static List<double> _signalValues(
    double? temp,
    double? humidity,
    double? soil,
    double? light,
  ) {
    if (temp == null && humidity == null && soil == null && light == null) {
      return const [];
    }
    return [
      _progress(temp, 0, 50) * 100,
      _progress(humidity, 0, 100) * 100,
      _progress(soil, 0, 3000) * 100,
      _progress(light, 0, 5000) * 100,
    ];
  }
}

class _HeaderIconFrame extends StatelessWidget {
  final Widget child;

  const _HeaderIconFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
        ),
      ),
      child: Center(child: child),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return _HeaderIconFrame(
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon),
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _DashboardHero extends StatelessWidget {
  final double? temp;
  final double? humidity;
  final double? soil;
  final double? light;
  final bool pumpOn;
  final bool isConnected;

  const _DashboardHero({
    required this.temp,
    required this.humidity,
    required this.soil,
    required this.light,
    required this.pumpOn,
    required this.isConnected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF10B981),
            Color(0xFF22D3EE),
            Color(0xFFF59E0B),
          ],
          stops: [0.0, 0.58, 1.0],
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.accentGreen),
      ),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppRadius.card - 4),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.button),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: const Icon(
                    Icons.eco_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Farm Overview',
                        style: theme.titleLarge?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        isConnected
                            ? 'Realtime greenhouse telemetry is active'
                            : 'Waiting for realtime sensor sync',
                        style:
                            theme.bodyMedium?.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: _HeroMiniMetric(
                    label: 'Temp',
                    value: _DashboardScreenState._format(temp, ' C'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _HeroMiniMetric(
                    label: 'Humidity',
                    value: _DashboardScreenState._format(humidity, '%'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _HeroMiniMetric(
                    label: 'Soil',
                    value: _DashboardScreenState._soilStatus(soil),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _HeroMiniMetric(
                    label: 'Pump',
                    value: pumpOn ? 'Running' : 'Standby',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMiniMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMiniMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.labelSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SensorList extends StatelessWidget {
  final double? temp;
  final double? humidity;
  final double? soil;
  final double? light;

  const _SensorList({
    required this.temp,
    required this.humidity,
    required this.soil,
    required this.light,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SensorMetricCard(
          label: 'Temperature',
          value: _DashboardScreenState._format(temp, ' C'),
          icon: Icons.thermostat_rounded,
          color: AppColors.accentOrange,
          progress: _DashboardScreenState._progress(temp, 0, 50),
          trend: temp != null && temp! > 30 ? 'up' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        SensorMetricCard(
          label: 'Humidity',
          value: _DashboardScreenState._format(humidity, '%'),
          icon: Icons.water_drop_rounded,
          color: AppColors.accentCyan,
          progress: _DashboardScreenState._progress(humidity, 0, 100),
          trend: humidity != null && humidity! < 45 ? 'down' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        SensorMetricCard(
          label: 'Soil Moisture',
          value: _DashboardScreenState._format(soil, '', decimals: 0),
          icon: Icons.grass_rounded,
          color: AppColors.accentGreen,
          progress: _DashboardScreenState._progress(soil, 0, 3000),
          trend: soil != null && soil! > 2200 ? 'down' : null,
        ),
        const SizedBox(height: AppSpacing.md),
        SensorMetricCard(
          label: 'Light Level',
          value: _DashboardScreenState._format(light, ' lx', decimals: 0),
          icon: Icons.light_mode_rounded,
          color: AppColors.accentPink,
          progress: _DashboardScreenState._progress(light, 0, 5000),
          trend: light != null && light! > 3500 ? 'up' : null,
        ),
      ],
    );
  }
}
