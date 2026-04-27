import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../services/sensor_history_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<List<SensorData>>(
        stream: FirebaseService.instance.historyStream(limit: 120),
        builder: (context, remoteSnapshot) {
          final remote = remoteSnapshot.data ?? const <SensorData>[];
          return ValueListenableBuilder<List<SensorData>>(
            valueListenable: SensorHistoryCacheService.instance.history,
            builder: (context, local, _) {
              if (remote.isNotEmpty) {
                SensorHistoryCacheService.instance.cacheSnapshots(remote);
              }
              final logs =
                  SensorHistoryCacheService.instance.mergeWithRemote(remote);
              final latest = logs.isEmpty ? null : logs.last;
              final isLoading =
                  remoteSnapshot.connectionState == ConnectionState.waiting &&
                      logs.isEmpty;

              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.xxl,
                ),
                children: [
                  DashboardHeader(
                    greeting: 'Activity Logs',
                    subtitle: logs.isEmpty
                        ? 'No recorded sensor history'
                        : '${logs.length} readings stored locally',
                    avatarText: 'L',
                    trailing: StatusBadge(
                      label: remote.isEmpty ? 'Local' : 'Synced',
                      icon: remote.isEmpty
                          ? Icons.storage_rounded
                          : Icons.cloud_done_rounded,
                      tone: remote.isEmpty
                          ? StatusBadgeTone.info
                          : StatusBadgeTone.success,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  if (isLoading)
                    const _LogsSkeleton()
                  else if (logs.isEmpty)
                    const EmptyStateWidget(
                      icon: Icons.history_rounded,
                      title: 'No logs yet',
                      subtitle:
                          'Sensor readings will appear here after Firebase or the local cache receives data.',
                    )
                  else ...[
                    _LogsHero(latest: latest!, count: logs.length),
                    const SizedBox(height: AppSpacing.xxl),
                    const SectionHeader(
                      title: 'Recent Readings',
                      subtitle: 'Firebase history merged with local cache',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...logs.reversed.take(40).map(
                          (log) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.md),
                            child: _LogTile(log: log),
                          ),
                        ),
                    if (remote.isEmpty) ...[
                      const SizedBox(height: AppSpacing.sm),
                      const AlertCard(
                        icon: Icons.storage_rounded,
                        title: 'Using local cached history',
                        message:
                            'Firebase history did not return records, so this list is using readings saved on this device.',
                        color: AppColors.primary,
                        tone: StatusBadgeTone.info,
                      ),
                    ],
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _LogsHero extends StatelessWidget {
  final SensorData latest;
  final int count;

  const _LogsHero({required this.latest, required this.count});

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
          colors: AppColors.violetCyanGradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.primary),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.timeline_rounded,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: '$count logs',
                icon: Icons.data_usage_rounded,
                tone: StatusBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Latest farm snapshot',
            style: theme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            DateFormat('MMM d, h:mm a').format(latest.timestamp),
            style: theme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroPill(
                label: 'Temp',
                value: '${latest.temperature?.toStringAsFixed(1) ?? '--'} C',
              ),
              _HeroPill(
                label: 'Humidity',
                value: '${latest.humidity?.toStringAsFixed(0) ?? '--'}%',
              ),
              _HeroPill(
                label: 'Pump',
                value: latest.pumpStatus ? 'On' : 'Off',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroPill({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  final SensorData log;

  const _LogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final time = DateFormat('MMM d, h:mm a').format(log.timestamp);
    final pumpTone =
        log.pumpStatus ? StatusBadgeTone.success : StatusBadgeTone.neutral;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(time, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Realtime sensor snapshot',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              StatusBadge(
                label: log.pumpStatus ? 'Pump on' : 'Pump off',
                tone: pumpTone,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _ReadingChip(
                icon: Icons.thermostat_rounded,
                label: 'Temp',
                value: '${log.temperature?.toStringAsFixed(1) ?? '--'} C',
                color: AppColors.accentRose,
              ),
              _ReadingChip(
                icon: Icons.water_drop_rounded,
                label: 'Humidity',
                value: '${log.humidity?.toStringAsFixed(0) ?? '--'}%',
                color: AppColors.accentCyan,
              ),
              _ReadingChip(
                icon: Icons.grass_rounded,
                label: 'Soil',
                value: log.soilMoisture?.toStringAsFixed(0) ?? '--',
                color: AppColors.accentGreen,
              ),
              _ReadingChip(
                icon: Icons.wb_sunny_rounded,
                label: 'Light',
                value: log.lightLevel?.toStringAsFixed(0) ?? '--',
                color: AppColors.accentOrange,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReadingChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ReadingChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.xs),
          Text(
            '$label: $value',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _LogsSkeleton extends StatelessWidget {
  const _LogsSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SoftWhiteCard(child: SizedBox(height: 160)),
        SizedBox(height: AppSpacing.md),
        SoftWhiteCard(child: SizedBox(height: 88)),
        SizedBox(height: AppSpacing.md),
        SoftWhiteCard(child: SizedBox(height: 88)),
      ],
    );
  }
}
