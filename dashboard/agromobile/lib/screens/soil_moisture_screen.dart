import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../services/sensor_history_cache_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/sensor_metric_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/charts/premium_doughnut_chart.dart';
import '../widgets/charts/premium_line_chart.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class SoilMoistureScreen extends StatelessWidget {
  const SoilMoistureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<SensorData?>(
        stream: FirebaseService.instance.currentDataStream(),
        initialData: FirebaseService.instance.latestSensorData,
        builder: (context, snapshot) {
          final data = snapshot.data;
          final moisture = data?.soilMoisture;
          final lastUpdated = data?.timestamp;
          final isLoading =
              snapshot.connectionState == ConnectionState.waiting &&
                  data == null;

          return ValueListenableBuilder<double>(
            valueListenable: SettingsService.instance.soilMoistureDryThreshold,
            builder: (context, dryThreshold, _) {
              return ValueListenableBuilder<List<SensorData>>(
                valueListenable: SensorHistoryCacheService.instance.history,
                builder: (context, history, __) {
                  final soilHistory = history
                      .map((item) => item.soilMoisture)
                      .whereType<double>()
                      .toList();

                  return RefreshIndicator(
                    onRefresh: () async {},
                    color: AppColors.primary,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.xl,
                        AppSpacing.md,
                        AppSpacing.xl,
                        AppSpacing.sectionLarge,
                      ),
                      children: [
                        const DashboardHeader(
                          leading: SizedBox(width: 36, height: 44),
                          greeting: 'Soil Moisture',
                          subtitle: 'Root-zone hydration and irrigation status',
                          avatarText: 'M',
                        ),
                        const SizedBox(height: AppSpacing.section),
                        _SoilHero(
                          moisture: moisture,
                          dryThreshold: dryThreshold,
                          lastUpdated: lastUpdated,
                        ),
                        if (isLoading) ...[
                          const SizedBox(height: AppSpacing.lg),
                          const AlertCard(
                            icon: Icons.sync_rounded,
                            title: 'Waiting for live data',
                            message:
                                'The latest soil moisture value will appear when Firebase sends a sensor snapshot.',
                            color: AppColors.primary,
                            tone: StatusBadgeTone.info,
                            timestamp: 'Syncing',
                          ),
                        ],
                        if (snapshot.hasError) ...[
                          const SizedBox(height: AppSpacing.lg),
                          AlertCard(
                            icon: Icons.cloud_off_rounded,
                            title: 'Soil stream unavailable',
                            message: 'Firebase returned: ${snapshot.error}',
                            color: AppColors.accentRose,
                            tone: StatusBadgeTone.error,
                            timestamp: 'Error',
                          ),
                        ],
                        const SizedBox(height: AppSpacing.sectionLarge),
                        const SectionHeader(
                          title: 'Current Reading',
                          subtitle: 'Raw sensor value and moisture health',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SensorMetricCard(
                          label: 'Raw Soil Moisture',
                          value: moisture == null
                              ? '--'
                              : moisture.toStringAsFixed(0),
                          icon: Icons.grass_rounded,
                          color: _statusColor(moisture, dryThreshold),
                          progress: _dryProgress(moisture),
                          trend: moisture != null && moisture > dryThreshold
                              ? 'down'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: SoftWhiteCard(
                                title: 'Moisture Health',
                                subtitle: _statusText(moisture, dryThreshold),
                                child: SizedBox(
                                  height: 150,
                                  child: PremiumDoughnutChart(
                                    value: _moistureHealth(moisture),
                                    centerLabel:
                                        '${(_moistureHealth(moisture) * 100).round()}%',
                                    color: _statusColor(moisture, dryThreshold),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: SoftWhiteCard(
                                title: 'Dry Limit',
                                subtitle: 'Alert threshold',
                                child: SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Text(
                                      dryThreshold.toStringAsFixed(0),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(
                                            color: AppColors.accentOrange,
                                          ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sectionLarge),
                        const SectionHeader(
                          title: 'Moisture Trend',
                          subtitle: 'Recent values cached on this device',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        SoftWhiteCard(
                          child: SizedBox(
                            height: 220,
                            child: soilHistory.isEmpty
                                ? Center(
                                    child: Text(
                                      'No cached soil history yet',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,
                                    ),
                                  )
                                : PremiumLineChart(
                                    values: soilHistory
                                        .skip(soilHistory.length > 24
                                            ? soilHistory.length - 24
                                            : 0)
                                        .toList(),
                                    color: AppColors.accentGreen,
                                    minY: 0,
                                    maxY: 4095,
                                  ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sectionLarge),
                        const SectionHeader(
                          title: 'Irrigation Guidance',
                          subtitle: 'Simple actions for stable root moisture',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const _TipsCard(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  static double _dryProgress(double? value) {
    if (value == null) return 0;
    return (value.clamp(0, 4095) / 4095).toDouble();
  }

  static double _moistureHealth(double? value) {
    if (value == null) return 0;
    return (1 - _dryProgress(value)).clamp(0.0, 1.0);
  }

  static String _statusText(double? value, double dryThreshold) {
    if (value == null) return 'Waiting for sensor data';
    if (value > dryThreshold) return 'Dry - irrigation recommended';
    if (value < 1200) return 'Wet - monitor drainage';
    return 'Optimal root moisture';
  }

  static Color _statusColor(double? value, double dryThreshold) {
    if (value == null) return AppColors.primary;
    if (value > dryThreshold) return AppColors.accentRose;
    if (value < 1200) return AppColors.accentCyan;
    return AppColors.accentGreen;
  }
}

class _SoilHero extends StatelessWidget {
  final double? moisture;
  final double dryThreshold;
  final DateTime? lastUpdated;

  const _SoilHero({
    required this.moisture,
    required this.dryThreshold,
    required this.lastUpdated,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final status = SoilMoistureScreen._statusText(moisture, dryThreshold);
    final updated = lastUpdated == null
        ? 'No timestamp'
        : DateFormat('MMM d, h:mm a').format(lastUpdated!);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.growthGradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.accentGreen),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(color: Colors.white24),
                ),
                child: const Icon(
                  Icons.grass_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Updated $updated',
                      style: theme.bodyMedium?.copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            moisture == null ? '--' : moisture!.toStringAsFixed(0),
            style: theme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Raw sensor value. Higher values indicate drier soil.',
            style: theme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: AppSpacing.lg),
          StatusBadge(
            label: moisture != null && moisture! > dryThreshold
                ? 'Needs attention'
                : 'Monitoring',
            tone: moisture != null && moisture! > dryThreshold
                ? StatusBadgeTone.error
                : StatusBadgeTone.success,
            icon: moisture != null && moisture! > dryThreshold
                ? Icons.warning_amber_rounded
                : Icons.check_circle_rounded,
          ),
        ],
      ),
    );
  }
}

class _TipsCard extends StatelessWidget {
  const _TipsCard();

  @override
  Widget build(BuildContext context) {
    return const SoftWhiteCard(
      child: Column(
        children: [
          _TipTile(
            icon: Icons.wb_twilight_rounded,
            title: 'Water at cooler times',
            subtitle:
                'Early morning or late evening watering reduces evaporation.',
            color: AppColors.accentOrange,
          ),
          SizedBox(height: AppSpacing.md),
          _TipTile(
            icon: Icons.opacity_rounded,
            title: 'Use slow irrigation',
            subtitle:
                'Drip irrigation keeps moisture stable and prevents runoff.',
            color: AppColors.accentCyan,
          ),
          SizedBox(height: AppSpacing.md),
          _TipTile(
            icon: Icons.eco_rounded,
            title: 'Avoid overwatering',
            subtitle:
                'Very wet soil can reduce oxygen around roots and invite disease.',
            color: AppColors.accentGreen,
          ),
        ],
      ),
    );
  }
}

class _TipTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _TipTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.chip),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(subtitle, style: theme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
