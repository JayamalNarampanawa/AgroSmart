import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../services/sensor_history_cache_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/sensor_metric_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  Future<void> _clearLocalCache() async {
    await SensorHistoryCacheService.instance.clear();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<SensorData?>(
        stream: FirebaseService.instance.currentDataStream(),
        initialData: FirebaseService.instance.latestSensorData,
        builder: (context, liveSnapshot) {
          final live = liveSnapshot.data;
          return StreamBuilder<List<SensorData>>(
            stream: FirebaseService.instance.historyStream(limit: 120),
            builder: (context, remoteSnapshot) {
              final remote = remoteSnapshot.data ?? const <SensorData>[];

              return ValueListenableBuilder<List<SensorData>>(
                valueListenable: SensorHistoryCacheService.instance.history,
                builder: (context, local, _) {
                  if (remote.isNotEmpty) {
                    SensorHistoryCacheService.instance.cacheSnapshots(remote);
                  }
                  final history = SensorHistoryCacheService.instance
                      .mergeWithRemote(remote);
                  final loading = remoteSnapshot.connectionState ==
                          ConnectionState.waiting &&
                      history.isEmpty;

                  return RefreshIndicator(
                    onRefresh: () async => setState(() {}),
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
                        DashboardHeader(
                          leading: const SizedBox(width: 36, height: 44),
                          greeting: 'Analytics',
                          subtitle:
                              '${history.length} samples - ${local.length} cached locally',
                          avatarText: 'S',
                          trailing: _SyncBadge(
                            remoteCount: remote.length,
                            localCount: local.length,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.section),
                        _AnalyticsHero(history: history, live: live),
                        const SizedBox(height: AppSpacing.sectionLarge),
                        SectionHeader(
                          title: 'Live Snapshot',
                          subtitle:
                              'Current readings are recorded locally for history',
                          actionText: loading ? 'Syncing' : 'Ready',
                          actionIcon: loading
                              ? Icons.sync_rounded
                              : Icons.history_rounded,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _LiveSnapshotList(data: live),
                        const SizedBox(height: AppSpacing.sectionLarge),
                        SectionHeader(
                          title: 'Trends',
                          subtitle:
                              'Firebase history merged with local Hive cache',
                          actionText: 'Clear local',
                          actionIcon: Icons.delete_sweep_rounded,
                          onAction: local.isEmpty ? null : _clearLocalCache,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        if (history.isEmpty)
                          const SoftWhiteCard(
                            child: EmptyStateWidget(
                              icon: Icons.analytics_outlined,
                              title: 'No recorded samples yet',
                              subtitle:
                                  'Keep the app open while Firebase sensor values update. New snapshots will be saved locally and shown here.',
                            ),
                          )
                        else ...[
                          _TrendChartCard(
                            title: 'Temperature',
                            subtitle: 'Greenhouse climate trend',
                            history: history,
                            getValue: (d) => d.temperature,
                            color: AppColors.accentOrange,
                            unit: ' C',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _TrendChartCard(
                            title: 'Humidity',
                            subtitle: 'Air moisture trend',
                            history: history,
                            getValue: (d) => d.humidity,
                            color: AppColors.accentCyan,
                            unit: '%',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _TrendChartCard(
                            title: 'Soil Moisture',
                            subtitle: 'Root-zone moisture trend',
                            history: history,
                            getValue: (d) => d.soilMoisture,
                            color: AppColors.accentGreen,
                            unit: '',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _TrendChartCard(
                            title: 'Light Level',
                            subtitle: 'Canopy exposure trend',
                            history: history,
                            getValue: (d) => d.lightLevel,
                            color: AppColors.accentPink,
                            unit: ' lx',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          _RecentSamplesCard(history: history),
                        ],
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
}

class _SyncBadge extends StatelessWidget {
  final int remoteCount;
  final int localCount;

  const _SyncBadge({
    required this.remoteCount,
    required this.localCount,
  });

  @override
  Widget build(BuildContext context) {
    final hasRemote = remoteCount > 0;
    return StatusBadge(
      label: hasRemote ? 'Firebase' : 'Local',
      tone: hasRemote ? StatusBadgeTone.success : StatusBadgeTone.info,
      icon: hasRemote ? Icons.cloud_done_rounded : Icons.storage_rounded,
    );
  }
}

class _AnalyticsHero extends StatelessWidget {
  final List<SensorData> history;
  final SensorData? live;

  const _AnalyticsHero({
    required this.history,
    required this.live,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final latest = history.isNotEmpty ? history.last : live;
    final lastUpdated = latest == null
        ? 'Waiting for data'
        : DateFormat('MMM d, HH:mm').format(latest.timestamp);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.primaryGradient,
        ),
        borderRadius: AppRadius.cardRadius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: const Icon(
                  Icons.query_stats_rounded,
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
                      'Sensor History',
                      style: theme.titleLarge?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Last update: $lastUpdated',
                      style: theme.bodyMedium?.copyWith(color: Colors.white70),
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
                child: _HeroMetric(
                  label: 'Samples',
                  value: history.length.toString(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _HeroMetric(
                  label: 'Avg Temp',
                  value: _avg(history, (d) => d.temperature, ' C'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _avg(
    List<SensorData> history,
    double? Function(SensorData) selector,
    String unit,
  ) {
    final values = history.map(selector).whereType<double>().toList();
    if (values.isEmpty) return '--';
    final avg = values.reduce((a, b) => a + b) / values.length;
    return '${avg.toStringAsFixed(1)}$unit';
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final String value;

  const _HeroMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.button),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: theme.labelSmall?.copyWith(color: Colors.white70)),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.titleMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}

class _LiveSnapshotList extends StatelessWidget {
  final SensorData? data;

  const _LiveSnapshotList({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SensorMetricCard(
          label: 'Temperature',
          value: _format(data?.temperature, ' C'),
          icon: Icons.thermostat_rounded,
          color: AppColors.accentOrange,
          progress: _progress(data?.temperature, 0, 50),
        ),
        const SizedBox(height: AppSpacing.md),
        SensorMetricCard(
          label: 'Humidity',
          value: _format(data?.humidity, '%'),
          icon: Icons.water_drop_rounded,
          color: AppColors.accentCyan,
          progress: _progress(data?.humidity, 0, 100),
        ),
        const SizedBox(height: AppSpacing.md),
        SensorMetricCard(
          label: 'Soil Moisture',
          value: _format(data?.soilMoisture, '', decimals: 0),
          icon: Icons.grass_rounded,
          color: AppColors.accentGreen,
          progress: _progress(data?.soilMoisture, 0, 3000),
        ),
        const SizedBox(height: AppSpacing.md),
        SensorMetricCard(
          label: 'Light Level',
          value: _format(data?.lightLevel, ' lx', decimals: 0),
          icon: Icons.light_mode_rounded,
          color: AppColors.accentPink,
          progress: _progress(data?.lightLevel, 0, 5000),
        ),
      ],
    );
  }

  static String _format(double? value, String unit, {int decimals = 1}) {
    if (value == null) return '--';
    return '${value.toStringAsFixed(decimals)}$unit';
  }

  static double _progress(double? value, double min, double max) {
    if (value == null || max <= min) return 0;
    return (value.clamp(min, max) - min) / (max - min);
  }
}

class _TrendChartCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<SensorData> history;
  final double? Function(SensorData) getValue;
  final Color color;
  final String unit;

  const _TrendChartCard({
    required this.title,
    required this.subtitle,
    required this.history,
    required this.getValue,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < history.length; i++) {
      final value = getValue(history[i]);
      if (value == null) continue;
      points.add(FlSpot(i.toDouble(), value));
      minY = math.min(minY, value);
      maxY = math.max(maxY, value);
    }

    if (points.isEmpty) {
      return SoftWhiteCard(
        title: title,
        subtitle: subtitle,
        child: const SizedBox(
          height: 150,
          child: Center(child: Text('No samples for this metric')),
        ),
      );
    }

    final range = maxY - minY;
    final padY = range < 1 ? 1.0 : range * 0.15;
    final current = points.last.y;

    return SoftWhiteCard(
      title: title,
      subtitle: subtitle,
      action: StatusBadge(
        label: '${current.toStringAsFixed(1)}$unit',
        tone: StatusBadgeTone.info,
      ),
      child: Column(
        children: [
          SizedBox(
            height: 210,
            child: LineChart(
              LineChartData(
                minY: minY - padY,
                maxY: maxY + padY,
                clipData: const FlClipData.all(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: AppColors.borderSoft.withValues(alpha: 0.55),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: _titlesData(context, history),
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => AppColors.textPrimary,
                    tooltipRoundedRadius: 14,
                    getTooltipItems: (spots) {
                      return spots
                          .map(
                            (spot) => LineTooltipItem(
                              '${spot.y.toStringAsFixed(1)}$unit',
                              const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          )
                          .toList();
                    },
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    curveSmoothness: 0.28,
                    color: color,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withValues(alpha: 0.22),
                          color.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 650),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(label: 'Min', value: '${minY.toStringAsFixed(1)}$unit'),
              _MiniStat(
                label: 'Current',
                value: '${current.toStringAsFixed(1)}$unit',
                color: color,
              ),
              _MiniStat(label: 'Max', value: '${maxY.toStringAsFixed(1)}$unit'),
            ],
          ),
        ],
      ),
    );
  }

  FlTitlesData _titlesData(BuildContext context, List<SensorData> history) {
    final theme = Theme.of(context).textTheme;
    final timeFormat = DateFormat('HH:mm');

    return FlTitlesData(
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 38,
          getTitlesWidget: (value, meta) {
            return Text(value.toInt().toString(), style: theme.labelSmall);
          },
        ),
      ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          interval: math.max(1, (history.length / 4).floorToDouble()),
          getTitlesWidget: (value, meta) {
            final index = value.toInt();
            if (index < 0 || index >= history.length) {
              return const SizedBox.shrink();
            }
            return Text(
              timeFormat.format(history[index].timestamp),
              style: theme.labelSmall,
            );
          },
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _MiniStat({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          value,
          style: theme.bodyLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(label, style: theme.labelSmall),
      ],
    );
  }
}

class _RecentSamplesCard extends StatelessWidget {
  final List<SensorData> history;

  const _RecentSamplesCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final latest = history.reversed.take(6).toList();
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      title: 'Recent Samples',
      subtitle: 'Last cached sensor records',
      child: Column(
        children: [
          for (var i = 0; i < latest.length; i++) ...[
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: const Icon(
                    Icons.history_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    DateFormat('MMM d, HH:mm').format(latest[i].timestamp),
                    style: theme.bodyLarge,
                  ),
                ),
                Text(
                  _LiveSnapshotList._format(latest[i].temperature, ' C'),
                  style: theme.bodyMedium,
                ),
              ],
            ),
            if (i != latest.length - 1)
              const Divider(height: AppSpacing.xl, color: AppColors.borderSoft),
          ],
        ],
      ),
    );
  }
}
