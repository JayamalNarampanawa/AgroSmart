import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_radius.dart';
import '../../theme/app_shadows.dart';
import '../../theme/app_spacing.dart';
import '../common/modern_action_button.dart';

class ModernBottomNavItem {
  final int index;
  final IconData icon;
  final String label;

  const ModernBottomNavItem({
    required this.index,
    required this.icon,
    required this.label,
  });
}

class ModernBottomNav extends StatelessWidget {
  final List<ModernBottomNavItem> items;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onCenterAction;

  const ModernBottomNav({
    super.key,
    required this.items,
    required this.selectedIndex,
    required this.onSelected,
    required this.onCenterAction,
  }) : assert(items.length == 4);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        bottomInset + AppSpacing.md,
      ),
      child: SizedBox(
        height: 76,
        child: Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              top: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.cardDark.withValues(alpha: 0.96)
                      : Colors.white.withValues(alpha: 0.94),
                  borderRadius: AppRadius.navRadius,
                  border: Border.all(
                    color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
                  ),
                  boxShadow: isDark ? [] : AppShadows.card,
                ),
                child: Row(
                  children: [
                    _NavItem(
                      item: items[0],
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                    ),
                    _NavItem(
                      item: items[1],
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                    ),
                    const SizedBox(width: 70),
                    _NavItem(
                      item: items[2],
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                    ),
                    _NavItem(
                      item: items[3],
                      selectedIndex: selectedIndex,
                      onSelected: onSelected,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 0,
              child: FloatingAddButton(
                icon: Icons.query_stats_rounded,
                onPressed: onCenterAction,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final ModernBottomNavItem item;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  const _NavItem({
    required this.item,
    required this.selectedIndex,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedIndex == item.index;
    final theme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final inactiveColor = isDark ? Colors.white54 : AppColors.textTertiary;

    return Expanded(
      child: InkWell(
        onTap: () => onSelected(item.index),
        borderRadius: BorderRadius.circular(AppRadius.button),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                item.icon,
                size: 21,
                color: selected ? AppColors.primary : inactiveColor,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.labelSmall?.copyWith(
                  color: selected ? AppColors.primary : inactiveColor,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
