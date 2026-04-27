import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class DashboardHeader extends StatelessWidget {
  final String greeting;
  final String subtitle;
  final Widget? leading;
  final Widget? trailing;
  final String avatarText;

  const DashboardHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    this.leading,
    this.trailing,
    this.avatarText = 'A',
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Row(
      children: [
        if (leading != null) ...[
          leading!,
          const SizedBox(width: AppSpacing.md),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        if (trailing != null) trailing!,
        const SizedBox(width: AppSpacing.sm),
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: AppColors.primaryGradient),
            borderRadius: BorderRadius.circular(AppRadius.button),
            boxShadow: AppShadows.softGlow(AppColors.primary),
          ),
          child: Text(
            avatarText.toUpperCase(),
            style: theme.titleMedium?.copyWith(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
