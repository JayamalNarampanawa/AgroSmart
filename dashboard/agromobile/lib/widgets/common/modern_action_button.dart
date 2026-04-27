import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';

enum ModernActionButtonStyle { primary, secondary }

class ModernActionButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ModernActionButtonStyle style;

  const ModernActionButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : style = ModernActionButtonStyle.primary;

  const ModernActionButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  }) : style = ModernActionButtonStyle.secondary;

  @override
  Widget build(BuildContext context) {
    final isPrimary = style == ModernActionButtonStyle.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        borderRadius: AppRadius.buttonRadius,
        boxShadow: isPrimary ? AppShadows.softGlow(AppColors.primary) : null,
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.primary : Colors.white,
          foregroundColor: isPrimary ? Colors.white : AppColors.primary,
          side:
              isPrimary ? null : const BorderSide(color: AppColors.borderSoft),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      ),
    );
  }
}

class FloatingAddButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;

  const FloatingAddButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient:
                const LinearGradient(colors: AppColors.violetCyanGradient),
            shape: BoxShape.circle,
            boxShadow: AppShadows.floating,
          ),
          child: IconButton(
            onPressed: onPressed,
            splashRadius: 30,
            iconSize: 30,
            color: Colors.white,
            icon: Icon(icon),
            tooltip: 'Quick action',
          ),
        ),
      ),
    );
  }
}
