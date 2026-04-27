import 'package:flutter/material.dart';

import '../../theme/app_radius.dart';
import '../../theme/app_spacing.dart';
import '../common/status_badge.dart';
import 'soft_white_card.dart';

class AlertCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? timestamp;
  final Color color;
  final StatusBadgeTone tone;

  const AlertCard({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    this.timestamp,
    this.tone = StatusBadgeTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Stack(
      children: [
        SoftWhiteCard(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.lg,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(icon, color: color, size: 21),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(title, style: theme.titleMedium)),
                        if (timestamp != null)
                          StatusBadge(label: timestamp!, tone: tone),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(message, style: theme.bodyMedium),
                  ],
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 16,
          bottom: 16,
          child: Container(
            width: 4,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ),
      ],
    );
  }
}
