import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/status_badge.dart';

class HealthCard extends StatelessWidget {
  final String title;
  final String status;
  final IconData icon;
  final StatusBadgeTone tone;
  final bool pulse;

  const HealthCard({
    super.key,
    required this.title,
    required this.status,
    required this.icon,
    this.tone = StatusBadgeTone.success,
    this.pulse = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForTone(tone);
    final theme = Theme.of(context).textTheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 240),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          _PulseIcon(color: color, icon: icon, enabled: pulse),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              title,
              style: theme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          StatusBadge(label: status, tone: tone),
        ],
      ),
    );
  }

  Color _colorForTone(StatusBadgeTone tone) {
    switch (tone) {
      case StatusBadgeTone.success:
        return AppColors.accentGreen;
      case StatusBadgeTone.warning:
        return AppColors.accentOrange;
      case StatusBadgeTone.error:
        return AppColors.accentRose;
      case StatusBadgeTone.info:
        return AppColors.primary;
      case StatusBadgeTone.neutral:
        return AppColors.textSecondary;
    }
  }
}

class _PulseIcon extends StatefulWidget {
  final Color color;
  final IconData icon;
  final bool enabled;

  const _PulseIcon({
    required this.color,
    required this.icon,
    required this.enabled,
  });

  @override
  State<_PulseIcon> createState() => _PulseIconState();
}

class _PulseIconState extends State<_PulseIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.enabled) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _PulseIcon oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.enabled && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.enabled && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = widget.enabled ? 1 + (_controller.value * 0.08) : 1.0;
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Icon(widget.icon, color: widget.color, size: 22),
      ),
    );
  }
}
