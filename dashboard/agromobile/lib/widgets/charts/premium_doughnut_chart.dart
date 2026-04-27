import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class PremiumDoughnutChart extends StatelessWidget {
  final double value;
  final String centerLabel;
  final Color color;

  const PremiumDoughnutChart({
    super.key,
    required this.value,
    required this.centerLabel,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final remaining = 1 - clamped;

    return Stack(
      alignment: Alignment.center,
      children: [
        PieChart(
          PieChartData(
            startDegreeOffset: -90,
            sectionsSpace: 4,
            centerSpaceRadius: 42,
            sections: [
              PieChartSectionData(
                value: clamped,
                color: color,
                radius: 16,
                showTitle: false,
              ),
              PieChartSectionData(
                value: remaining <= 0 ? 0.001 : remaining,
                color: AppColors.borderSoft,
                radius: 16,
                showTitle: false,
              ),
            ],
          ),
          swapAnimationDuration: const Duration(milliseconds: 650),
          swapAnimationCurve: Curves.easeOutCubic,
        ),
        Text(
          centerLabel,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
