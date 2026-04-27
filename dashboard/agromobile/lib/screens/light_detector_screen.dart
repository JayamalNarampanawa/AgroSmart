import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/sensor_metric_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/charts/premium_line_chart.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class LightDetectorScreen extends StatefulWidget {
  const LightDetectorScreen({super.key});

  @override
  State<LightDetectorScreen> createState() => _LightDetectorScreenState();
}

class _LightDetectorScreenState extends State<LightDetectorScreen> {
  final List<double> _lightData = [];
  StreamSubscription<SensorData?>? _sensorSubscription;
  SensorData? _latestData;

  @override
  void initState() {
    super.initState();
    final cached = FirebaseService.instance.latestSensorData;
    if (cached != null) {
      _latestData = cached;
      _pushPoint(cached.lightLevel);
    }
    _sensorSubscription =
        FirebaseService.instance.currentDataStream().listen((data) {
      if (!mounted || data == null) return;
      setState(() {
        _latestData = data;
        _pushPoint(data.lightLevel);
      });
    });
  }

  @override
  void dispose() {
    _sensorSubscription?.cancel();
    super.dispose();
  }

  void _pushPoint(double? value) {
    if (value == null) return;
    if (_lightData.length >= 30) _lightData.removeAt(0);
    _lightData.add(value);
  }

  @override
  Widget build(BuildContext context) {
    final light = _latestData?.lightLevel;
    final color = _getLevelColor(light);
    final levelText = _getLevelText(light);
    final levelIcon = _getLevelIcon(light);
    final chartMaxY = _chartMaxY(_lightData, light);
    final updated = _latestData == null
        ? 'Waiting for live sensor data'
        : 'Updated ${DateFormat('h:mm a').format(_latestData!.timestamp)}';

    return AppScaffold(
      bottomInset: 110,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DashboardHeader(
              greeting: 'Light Detector',
              subtitle: updated,
              avatarText: 'L',
              trailing: StatusBadge(
                label: levelText,
                icon: levelIcon,
                tone: _getBadgeTone(light),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _LightHero(
              light: light,
              color: color,
              levelText: levelText,
              levelIcon: levelIcon,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Light Reading',
              subtitle: 'Current illumination inside the crop area',
            ),
            const SizedBox(height: AppSpacing.md),
            SensorMetricCard(
              label: 'Light Intensity',
              value: light == null ? '--' : '${light.toStringAsFixed(0)} lux',
              icon: levelIcon,
              color: color,
              progress: ((light ?? 0) / 1200).clamp(0.0, 1.0).toDouble(),
              trend:
                  light != null && light >= 200 && light <= 1200 ? 'up' : null,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Live Trend',
              subtitle: 'Recent light sensor samples',
            ),
            const SizedBox(height: AppSpacing.md),
            SoftWhiteCard(
              child: SizedBox(
                height: 220,
                child: PremiumLineChart(
                  values: _lightData,
                  color: color,
                  minY: 0,
                  maxY: chartMaxY,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Light Guide',
              subtitle: 'Quick interpretation for crop lighting',
            ),
            const SizedBox(height: AppSpacing.md),
            const SoftWhiteCard(
              child: Column(
                children: [
                  _GuideRow(
                    icon: Icons.nightlight_round,
                    label: 'Low light',
                    range: '< 200 lux',
                    description: 'Shade, night, or indoor conditions.',
                    color: AppColors.accentCyan,
                  ),
                  Divider(height: AppSpacing.xxl),
                  _GuideRow(
                    icon: Icons.wb_cloudy_rounded,
                    label: 'Moderate light',
                    range: '200 - 800 lux',
                    description: 'Cloudy day or partial greenhouse shade.',
                    color: AppColors.accentOrange,
                  ),
                  Divider(height: AppSpacing.xxl),
                  _GuideRow(
                    icon: Icons.wb_sunny_rounded,
                    label: 'High light',
                    range: '> 800 lux',
                    description: 'Bright direct light for strong growth.',
                    color: AppColors.accentGreen,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AlertCard(
              icon: _alertIcon(light),
              title: _alertTitle(light),
              message: _alertMessage(light),
              color: color,
              tone: _getBadgeTone(light),
            ),
          ],
        ),
      ),
    );
  }

  static Color _getLevelColor(double? light) {
    if (light == null) return AppColors.textSecondary;
    if (light < 200) return AppColors.accentCyan;
    if (light < 800) return AppColors.accentOrange;
    return AppColors.accentGreen;
  }

  static double _chartMaxY(List<double> values, double? current) {
    var maxValue = 1200.0;
    for (final value in values) {
      if (value > maxValue) maxValue = value;
    }
    if (current != null && current > maxValue) maxValue = current;
    return maxValue + (maxValue * 0.12);
  }

  static String _getLevelText(double? light) {
    if (light == null) return 'No data';
    if (light < 200) return 'Low';
    if (light < 800) return 'Medium';
    return 'High';
  }

  static IconData _getLevelIcon(double? light) {
    if (light == null) return Icons.wb_sunny_outlined;
    if (light < 200) return Icons.nightlight_round;
    if (light < 800) return Icons.wb_cloudy_rounded;
    return Icons.wb_sunny_rounded;
  }

  static StatusBadgeTone _getBadgeTone(double? light) {
    if (light == null) return StatusBadgeTone.neutral;
    if (light < 200) return StatusBadgeTone.warning;
    return StatusBadgeTone.success;
  }

  static IconData _alertIcon(double? light) {
    if (light == null) return Icons.sensors_off_rounded;
    if (light < 200) return Icons.tips_and_updates_rounded;
    if (light > 1600) return Icons.wb_sunny_rounded;
    return Icons.eco_rounded;
  }

  static String _alertTitle(double? light) {
    if (light == null) return 'Waiting for light sensor';
    if (light < 200) return 'Light is below the ideal range';
    if (light > 1600) return 'Strong direct light detected';
    return 'Light level supports growth';
  }

  static String _alertMessage(double? light) {
    if (light == null) {
      return 'The app will update this page as soon as Firebase receives a light reading.';
    }
    if (light < 200) {
      return 'Consider moving crops closer to natural light or extending grow light time.';
    }
    if (light > 1600) {
      return 'Watch for heat stress and keep soil moisture in a healthy range.';
    }
    return 'Continue routine monitoring and keep the canopy evenly exposed.';
  }
}

class _LightHero extends StatelessWidget {
  final double? light;
  final Color color;
  final String levelText;
  final IconData levelIcon;

  const _LightHero({
    required this.light,
    required this.color,
    required this.levelText,
    required this.levelIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color,
            AppColors.primary,
          ],
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(color),
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
                child: Icon(levelIcon, color: Colors.white, size: 32),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: AppRadius.chipRadius,
                ),
                child: Text(
                  levelText,
                  style: theme.labelSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              light == null ? '--' : '${light!.toStringAsFixed(0)} lux',
              style: theme.displayLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Live canopy illumination',
            style: theme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String range;
  final String description;
  final Color color;

  const _GuideRow({
    required this.icon,
    required this.label,
    required this.range,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Row(
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
              Row(
                children: [
                  Expanded(child: Text(label, style: theme.titleMedium)),
                  StatusBadge(label: range, tone: StatusBadgeTone.info),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: theme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
