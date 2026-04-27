import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/health_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/modern_action_button.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

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

  final List<Map<String, dynamic>> alertHistory = [
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
    if (!mounted) return;
    final now =
        '${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}:${DateTime.now().second.toString().padLeft(2, '0')}';
    setState(() {
      isAlarmTriggered = true;
      lastAlert = 'Motion detected - $now';
    });

    Timer(const Duration(seconds: 10), () {
      if (mounted) {
        setState(() {
          isAlarmTriggered = false;
        });
      }
    });
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
          isAlarmActive
              ? 'Security system activated'
              : 'Security system deactivated',
        ),
        backgroundColor:
            isAlarmActive ? AppColors.accentGreen : AppColors.accentRose,
        behavior: SnackBarBehavior.floating,
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
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Color _getStatusColor() {
    if (!isAlarmActive) return AppColors.textSecondary;
    if (isAlarmTriggered) return AppColors.accentRose;
    return AppColors.accentGreen;
  }

  String _getStatusText() {
    if (!isAlarmActive) return 'Disabled';
    if (isAlarmTriggered) return 'Alert';
    return 'Armed';
  }

  StatusBadgeTone _getStatusTone() {
    if (!isAlarmActive) return StatusBadgeTone.neutral;
    if (isAlarmTriggered) return StatusBadgeTone.error;
    return StatusBadgeTone.success;
  }

  @override
  Widget build(BuildContext context) {
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
              greeting: 'Security Alarm',
              subtitle: isAlarmTriggered
                  ? 'Immediate action required'
                  : 'Farm perimeter monitoring',
              avatarText: 'S',
              trailing: StatusBadge(
                label: _getStatusText(),
                icon: isAlarmTriggered
                    ? Icons.warning_rounded
                    : Icons.shield_rounded,
                tone: _getStatusTone(),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            _SecurityHero(
              active: isAlarmActive,
              triggered: isAlarmTriggered,
              status: _getStatusText(),
              statusColor: _getStatusColor(),
              onAcknowledge: _acknowledgeAlert,
            ),
            const SizedBox(height: AppSpacing.xxl),
            SoftWhiteCard(
              title: 'Security Control',
              subtitle: isAlarmActive
                  ? 'Sensors are watching the farm perimeter.'
                  : 'Monitoring is paused until re-enabled.',
              action: StatusBadge(
                label: isAlarmActive ? 'Online' : 'Offline',
                tone: isAlarmActive
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.neutral,
              ),
              child: SizedBox(
                width: double.infinity,
                child: isAlarmActive
                    ? ModernActionButton.secondary(
                        label: 'Disable Security',
                        icon: Icons.security_outlined,
                        onPressed: _toggleAlarmSystem,
                      )
                    : ModernActionButton.primary(
                        label: 'Enable Security',
                        icon: Icons.security_rounded,
                        onPressed: _toggleAlarmSystem,
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Security Zones',
              subtitle: 'Perimeter and equipment monitoring points',
            ),
            const SizedBox(height: AppSpacing.md),
            const HealthCard(
              title: 'Field Perimeter',
              status: 'Active',
              icon: Icons.fence_rounded,
              tone: StatusBadgeTone.success,
            ),
            const SizedBox(height: AppSpacing.md),
            const HealthCard(
              title: 'Equipment Shed',
              status: 'Active',
              icon: Icons.warehouse_rounded,
              tone: StatusBadgeTone.success,
            ),
            const SizedBox(height: AppSpacing.md),
            const HealthCard(
              title: 'Water Tank Area',
              status: 'Active',
              icon: Icons.videocam_rounded,
              tone: StatusBadgeTone.success,
            ),
            const SizedBox(height: AppSpacing.md),
            const HealthCard(
              title: 'Main Gate',
              status: 'Offline',
              icon: Icons.sensor_door_rounded,
              tone: StatusBadgeTone.error,
              pulse: true,
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Recent Alerts',
              subtitle: 'Latest security events and resolved incidents',
            ),
            const SizedBox(height: AppSpacing.md),
            if (isAlarmTriggered) ...[
              AlertCard(
                icon: Icons.warning_rounded,
                title: 'Security breach detected',
                message: lastAlert,
                color: AppColors.accentRose,
                tone: StatusBadgeTone.error,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            ...alertHistory.map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _AlertHistoryTile(alert: alert),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'System Information',
              subtitle: 'Security device health snapshot',
            ),
            const SizedBox(height: AppSpacing.md),
            SoftWhiteCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'System Status',
                    value: _getStatusText(),
                    color: _getStatusColor(),
                  ),
                  const _InfoRow(label: 'Active Sensors', value: '8 of 8'),
                  const _InfoRow(
                      label: 'Last System Check', value: '5 min ago'),
                  const _InfoRow(label: 'Battery Backup', value: '98%'),
                  const _InfoRow(label: 'Network Connection', value: 'Strong'),
                  _InfoRow(label: 'Last Alert', value: lastAlert),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityHero extends StatelessWidget {
  final bool active;
  final bool triggered;
  final String status;
  final Color statusColor;
  final VoidCallback onAcknowledge;

  const _SecurityHero({
    required this.active,
    required this.triggered,
    required this.status,
    required this.statusColor,
    required this.onAcknowledge,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final gradient = triggered
        ? const [Color(0xFFF43F5E), Color(0xFFEC4899)]
        : active
            ? const [Color(0xFF10B981), Color(0xFF22D3EE)]
            : const [Color(0xFF6B7280), Color(0xFF374151)];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(statusColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                ),
                child: Icon(
                  triggered
                      ? Icons.warning_rounded
                      : active
                          ? Icons.shield_rounded
                          : Icons.shield_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: status,
                tone: triggered
                    ? StatusBadgeTone.error
                    : active
                        ? StatusBadgeTone.success
                        : StatusBadgeTone.neutral,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            triggered
                ? 'Breach detected'
                : active
                    ? 'System armed'
                    : 'System disabled',
            style: theme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            triggered
                ? 'Check the perimeter and acknowledge the event.'
                : active
                    ? 'Security sensors are monitoring the farm.'
                    : 'Enable security to resume monitoring.',
            style: theme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.84),
            ),
          ),
          if (triggered) ...[
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: ModernActionButton.primary(
                label: 'Acknowledge Alert',
                icon: Icons.check_rounded,
                onPressed: onAcknowledge,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AlertHistoryTile extends StatelessWidget {
  final Map<String, dynamic> alert;

  const _AlertHistoryTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    final severity = alert['severity']?.toString() ?? 'Low';
    final resolved = alert['resolved'] == true;
    final color = severity == 'High'
        ? AppColors.accentRose
        : severity == 'Medium'
            ? AppColors.accentOrange
            : AppColors.accentGreen;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(
              resolved ? Icons.task_alt_rounded : Icons.priority_high_rounded,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  alert['type']?.toString() ?? 'Security Alert',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${alert['location']} - ${alert['time']}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          StatusBadge(
            label: resolved ? 'Resolved' : severity,
            tone: resolved ? StatusBadgeTone.success : StatusBadgeTone.error,
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
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.titleMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
