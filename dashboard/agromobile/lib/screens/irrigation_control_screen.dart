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
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/modern_action_button.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class IrrigationControlScreen extends StatefulWidget {
  const IrrigationControlScreen({super.key});

  @override
  State<IrrigationControlScreen> createState() =>
      _IrrigationControlScreenState();
}

class _IrrigationControlScreenState extends State<IrrigationControlScreen> {
  bool isIrrigationActive = false;
  bool isAutoMode = true;
  double flowRate = 0.0;
  int duration = 0;
  SensorData? _latestSensorData;
  Timer? _irrigationTimer;
  Timer? _updateTimer;
  StreamSubscription<SensorData?>? _sensorSubscription;

  final Map<String, bool> _scheduleEnabled = {
    'Morning': true,
    'Afternoon': false,
    'Evening': true,
  };

  @override
  void initState() {
    super.initState();
    final cached = FirebaseService.instance.latestSensorData;
    _latestSensorData = cached;
    if (cached != null) {
      isIrrigationActive = cached.pumpStatus;
      if (isIrrigationActive) flowRate = 2.5;
    }
    _sensorSubscription =
        FirebaseService.instance.currentDataStream().listen((data) {
      if (data != null && mounted) {
        setState(() {
          _latestSensorData = data;
          isIrrigationActive = data.pumpStatus;
          if (!isIrrigationActive) flowRate = 0.0;
        });
      }
    });
    _startDataUpdate();
  }

  @override
  void dispose() {
    _irrigationTimer?.cancel();
    _updateTimer?.cancel();
    _sensorSubscription?.cancel();
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
    FirebaseService.instance.togglePump();
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
        backgroundColor:
            isIrrigationActive ? AppColors.accentGreen : AppColors.accentRose,
        behavior: SnackBarBehavior.floating,
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
    final data = _latestSensorData;
    final soil = data?.soilMoisture ?? 0;
    final waterLevel = data?.waterLevelPercent;
    final updated = data == null
        ? 'Waiting for live sensor data'
        : 'Updated ${DateFormat('h:mm a').format(data.timestamp)}';

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
              greeting: 'Irrigation Control',
              subtitle: updated,
              avatarText: 'I',
              trailing: StatusBadge(
                label: isIrrigationActive ? 'Running' : 'Standby',
                icon: isIrrigationActive
                    ? Icons.water_drop_rounded
                    : Icons.pause_rounded,
                tone: isIrrigationActive
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.neutral,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _PumpHero(
              active: isIrrigationActive,
              flowRate: flowRate,
              duration: duration,
              autoMode: isAutoMode,
              onToggle: _toggleIrrigation,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Live Watering',
              subtitle: 'Pump output and crop bed moisture',
            ),
            const SizedBox(height: AppSpacing.md),
            SensorMetricCard(
              label: 'Flow Rate',
              value: '${flowRate.toStringAsFixed(1)} L/min',
              icon: Icons.speed_rounded,
              color: AppColors.accentCyan,
              progress: (flowRate / 4).clamp(0.0, 1.0).toDouble(),
              trend: isIrrigationActive ? 'up' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SensorMetricCard(
              label: 'Soil Moisture',
              value: '${soil.toStringAsFixed(0)}%',
              icon: Icons.grass_rounded,
              color: _soilColor(soil),
              progress: (soil / 100).clamp(0.0, 1.0).toDouble(),
              trend: soil >= 35 && soil <= 75 ? 'up' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            SensorMetricCard(
              label: 'Session Runtime',
              value: '$duration min',
              icon: Icons.timer_rounded,
              color: AppColors.primary,
              progress: (duration / 60).clamp(0.0, 1.0).toDouble(),
              trend: isIrrigationActive ? 'up' : null,
            ),
            if (waterLevel != null) ...[
              const SizedBox(height: AppSpacing.md),
              SensorMetricCard(
                label: 'Water Reserve',
                value: '${waterLevel.toStringAsFixed(0)}%',
                icon: Icons.local_drink_rounded,
                color: AppColors.accentGreen,
                progress: (waterLevel / 100).clamp(0.0, 1.0).toDouble(),
                trend: waterLevel >= 25 ? 'up' : null,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            SoftWhiteCard(
              title: 'Operation Mode',
              subtitle: isAutoMode
                  ? 'System follows soil moisture readings.'
                  : 'Manual control is enabled.',
              action: StatusBadge(
                label: isAutoMode ? 'Auto' : 'Manual',
                tone: isAutoMode
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.warning,
              ),
              child: Row(
                children: [
                  _ModeIcon(enabled: isAutoMode),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Text(
                      isAutoMode
                          ? 'Automatic mode keeps irrigation aligned with the greenhouse moisture threshold.'
                          : 'Manual mode lets you start or stop the pump from this screen.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Switch.adaptive(
                    value: isAutoMode,
                    activeThumbColor: AppColors.accentGreen,
                    onChanged: (_) => _toggleAutoMode(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Watering Plan',
              subtitle: 'Local quick schedule for the next crop cycle',
            ),
            const SizedBox(height: AppSpacing.md),
            SoftWhiteCard(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                children: [
                  _ScheduleTile(
                    title: 'Morning',
                    time: '06:00 AM',
                    icon: Icons.wb_twilight_rounded,
                    enabled: _scheduleEnabled['Morning'] ?? false,
                    onChanged: (value) =>
                        setState(() => _scheduleEnabled['Morning'] = value),
                  ),
                  _ScheduleTile(
                    title: 'Afternoon',
                    time: '02:00 PM',
                    icon: Icons.wb_sunny_rounded,
                    enabled: _scheduleEnabled['Afternoon'] ?? false,
                    onChanged: (value) =>
                        setState(() => _scheduleEnabled['Afternoon'] = value),
                  ),
                  _ScheduleTile(
                    title: 'Evening',
                    time: '06:00 PM',
                    icon: Icons.nights_stay_rounded,
                    enabled: _scheduleEnabled['Evening'] ?? false,
                    onChanged: (value) =>
                        setState(() => _scheduleEnabled['Evening'] = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'System Health',
              subtitle: 'Pump state, pressure, and daily usage',
            ),
            const SizedBox(height: AppSpacing.md),
            SoftWhiteCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Pump Status',
                    value: isIrrigationActive ? 'Running' : 'Stopped',
                    color: isIrrigationActive
                        ? AppColors.accentGreen
                        : AppColors.textSecondary,
                  ),
                  const _InfoRow(label: 'Pressure', value: '2.3 Bar'),
                  _InfoRow(
                      label: 'Total Runtime Today', value: '$duration min'),
                  _InfoRow(
                    label: 'Water Used Today',
                    value: '${(duration * flowRate).toStringAsFixed(1)} L',
                  ),
                  _InfoRow(
                    label: 'Next Scheduled',
                    value: _nextScheduleLabel(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AlertCard(
              icon: isIrrigationActive
                  ? Icons.opacity_rounded
                  : Icons.eco_rounded,
              title: isIrrigationActive
                  ? 'Pump is watering the active zone'
                  : 'Ready for the next irrigation cycle',
              message: isIrrigationActive
                  ? 'Keep monitoring soil moisture and stop the pump when the bed reaches the target range.'
                  : 'Use the start button for a manual session or keep auto mode enabled for sensor-driven control.',
              color: isIrrigationActive
                  ? AppColors.accentCyan
                  : AppColors.accentGreen,
              tone: isIrrigationActive
                  ? StatusBadgeTone.info
                  : StatusBadgeTone.success,
            ),
          ],
        ),
      ),
    );
  }

  String _nextScheduleLabel() {
    final entries = _scheduleEnabled.entries.where((entry) => entry.value);
    if (entries.isEmpty) return 'No local schedule';
    return switch (entries.first.key) {
      'Morning' => '06:00 AM',
      'Afternoon' => '02:00 PM',
      'Evening' => '06:00 PM',
      _ => 'Ready',
    };
  }

  static Color _soilColor(double value) {
    if (value <= 0) return AppColors.textSecondary;
    if (value < 35) return AppColors.accentOrange;
    if (value > 75) return AppColors.accentCyan;
    return AppColors.accentGreen;
  }
}

class _PumpHero extends StatelessWidget {
  final bool active;
  final double flowRate;
  final int duration;
  final bool autoMode;
  final VoidCallback onToggle;

  const _PumpHero({
    required this.active,
    required this.flowRate,
    required this.duration,
    required this.autoMode,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final colors = active
        ? const [Color(0xFF0EA5E9), Color(0xFF10B981)]
        : const [Color(0xFF6D5DF6), Color(0xFF22D3EE)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(active ? colors.last : colors.first),
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
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  active ? Icons.water_drop_rounded : Icons.power_settings_new,
                  color: Colors.white,
                  size: 30,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: autoMode ? 'Auto logic' : 'Manual',
                icon: autoMode ? Icons.auto_awesome_rounded : Icons.touch_app,
                tone: autoMode ? StatusBadgeTone.success : StatusBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            active ? 'Pump running' : 'Pump is on standby',
            style: theme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            active
                ? '${flowRate.toStringAsFixed(1)} L/min flowing for $duration min'
                : 'Start a manual irrigation session when the bed needs water.',
            style: theme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.82),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: double.infinity,
            child: ModernActionButton.primary(
              label: active ? 'Stop Irrigation' : 'Start Irrigation',
              icon: active ? Icons.stop_rounded : Icons.play_arrow_rounded,
              onPressed: onToggle,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeIcon extends StatelessWidget {
  final bool enabled;

  const _ModeIcon({required this.enabled});

  @override
  Widget build(BuildContext context) {
    final color = enabled ? AppColors.accentGreen : AppColors.accentOrange;
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Icon(
        enabled ? Icons.auto_mode_rounded : Icons.tune_rounded,
        color: color,
      ),
    );
  }
}

class _ScheduleTile extends StatelessWidget {
  final String title;
  final String time;
  final IconData icon;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _ScheduleTile({
    required this.title,
    required this.time,
    required this.icon,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final color = enabled ? AppColors.primary : AppColors.textTertiary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: enabled ? 0.10 : 0.05),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
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
                Text(title, style: theme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(time, style: theme.bodyMedium),
              ],
            ),
          ),
          Switch.adaptive(
            value: enabled,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;

  const _InfoRow({
    required this.label,
    required this.value,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Text(
            value,
            style: theme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
