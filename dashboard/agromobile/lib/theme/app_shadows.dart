import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppShadows {
  const AppShadows._();

  static List<BoxShadow> card = [
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.06),
      offset: const Offset(0, 10),
      blurRadius: 26,
    ),
    BoxShadow(
      color: AppColors.textPrimary.withValues(alpha: 0.03),
      offset: const Offset(0, 2),
      blurRadius: 8,
    ),
  ];

  static List<BoxShadow> floating = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha: 0.20),
      offset: const Offset(0, 16),
      blurRadius: 30,
    ),
  ];

  static List<BoxShadow> softGlow(Color color) => [
        BoxShadow(
          color: color.withValues(alpha: 0.24),
          offset: const Offset(0, 14),
          blurRadius: 32,
        ),
      ];
}
