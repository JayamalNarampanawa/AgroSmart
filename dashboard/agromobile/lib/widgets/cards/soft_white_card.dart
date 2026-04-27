import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

class SoftWhiteCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final String? title;
  final String? subtitle;
  final Widget? action;
  final Color? backgroundColor;

  const SoftWhiteCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.xl),
    this.title,
    this.subtitle,
    this.action,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context).textTheme;
    final surface =
        backgroundColor ?? (isDark ? AppColors.cardDark : AppColors.cardWhite);
    final borderColor = isDark ? AppColors.darkBorder : AppColors.borderSoft;

    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: borderColor.withValues(alpha: 0.75)),
        boxShadow: isDark ? [] : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || subtitle != null || action != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (title != null) Text(title!, style: theme.titleMedium),
                      if (subtitle != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(subtitle!, style: theme.bodyMedium),
                      ],
                    ],
                  ),
                ),
                if (action != null) action!,
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          child,
        ],
      ),
    );
  }
}
