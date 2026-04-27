import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analytics_point.dart';
import '../theme/app_colors.dart';

class TemperatureHumidityChart extends StatelessWidget {
  final List<AnalyticsPoint> points;

  const TemperatureHumidityChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _empty('No sensor history yet');
    }
    final tempSpots = <FlSpot>[];
    final humiditySpots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final x = i.toDouble();
      if (point.temperature != null) {
        tempSpots.add(FlSpot(x, point.temperature!));
      }
      if (point.humidity != null) {
        humiditySpots.add(FlSpot(x, point.humidity!));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.borderSoft.withValues(alpha: 0.7),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: _touchData(),
        lineBarsData: [
          LineChartBarData(
            spots: tempSpots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            color: AppColors.accentRose,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accentRose.withValues(alpha: 0.08),
            ),
          ),
          LineChartBarData(
            spots: humiditySpots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            color: AppColors.accentCyan,
            belowBarData: BarAreaData(
              show: true,
              color: AppColors.accentCyan.withValues(alpha: 0.06),
            ),
          ),
        ],
      ),
    );
  }
}

class SoilMoistureChart extends StatelessWidget {
  final List<AnalyticsPoint> points;

  const SoilMoistureChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _empty('No soil moisture data');
    }
    final spots = <FlSpot>[];
    for (var i = 0; i < points.length; i++) {
      final value = points[i].soilMoisture;
      if (value != null) {
        spots.add(FlSpot(i.toDouble(), value));
      }
    }

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) => FlLine(
            color: AppColors.borderSoft.withValues(alpha: 0.7),
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: _touchData(),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.28,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            color: AppColors.accentGreen,
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  AppColors.accentGreen.withValues(alpha: 0.20),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        extraLinesData: ExtraLinesData(horizontalLines: [
          HorizontalLine(
            y: 1200,
            color: AppColors.accentOrange.withValues(alpha: 0.35),
            dashArray: [6, 4],
          ),
          HorizontalLine(
            y: 2200,
            color: AppColors.accentGreen.withValues(alpha: 0.35),
            dashArray: [6, 4],
          ),
        ]),
      ),
    );
  }
}

class PumpActivityChart extends StatelessWidget {
  final List<AnalyticsPoint> points;

  const PumpActivityChart({super.key, required this.points});

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
      return _empty('No pump activity');
    }
    final grouped = <String, int>{};
    for (final point in points) {
      final day = DateUtils.dateOnly(point.timestamp).toIso8601String().substring(0, 10);
      if (point.pumpStatus) {
        grouped[day] = (grouped[day] ?? 0) + 1;
      }
    }
    if (grouped.isEmpty) {
      return _empty('No pump activity');
    }
    final entries = grouped.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceBetween,
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: 14,
                  gradient: const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: AppColors.violetCyanGradient,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class MoistureStatusPie extends StatelessWidget {
  final double? soilMoisture;

  const MoistureStatusPie({super.key, required this.soilMoisture});

  @override
  Widget build(BuildContext context) {
    if (soilMoisture == null) {
      return _empty('No soil data');
    }
    final dry = (soilMoisture ?? 0) > 2200 ? 70.0 : 20.0;
    final optimal = (soilMoisture ?? 0) > 1200 && (soilMoisture ?? 0) <= 2200 ? 70.0 : 20.0;
    final wet = (soilMoisture ?? 0) <= 1200 ? 70.0 : 20.0;
    return PieChart(
      PieChartData(
        sectionsSpace: 4,
        centerSpaceRadius: 34,
        sections: [
          PieChartSectionData(
            value: dry,
            color: AppColors.accentOrange,
            radius: 16,
            showTitle: false,
          ),
          PieChartSectionData(
            value: optimal,
            color: AppColors.accentGreen,
            radius: 16,
            showTitle: false,
          ),
          PieChartSectionData(
            value: wet,
            color: AppColors.accentCyan,
            radius: 16,
            showTitle: false,
          ),
        ],
      ),
    );
  }
}

Widget _empty(String label) {
  return Center(
    child: Text(
      label,
      style: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}

LineTouchData _touchData() {
  return LineTouchData(
    handleBuiltInTouches: true,
    touchTooltipData: LineTouchTooltipData(
      getTooltipColor: (_) => AppColors.textPrimary,
      tooltipRoundedRadius: 14,
      tooltipPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      getTooltipItems: (spots) {
        return spots
            .map(
              (spot) => LineTooltipItem(
                spot.y.toStringAsFixed(1),
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
            .toList();
      },
    ),
  );
}

