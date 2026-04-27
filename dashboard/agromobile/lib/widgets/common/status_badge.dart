import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';

enum StatusBadgeTone { success, warning, error, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusBadgeTone tone;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    this.tone = StatusBadgeTone.info,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final color = _colorForTone(tone);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w800,
                ),
          ),
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
