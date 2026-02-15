import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../models/analytics_point.dart';

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
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: tempSpots,
            isCurved: true,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            color: const Color(0xFFFB7185),
          ),
          LineChartBarData(
            spots: humiditySpots,
            isCurved: true,
            barWidth: 2.0,
            dotData: const FlDotData(show: false),
            color: const Color(0xFF38BDF8),
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
        gridData: FlGridData(show: true, drawVerticalLine: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            barWidth: 2.5,
            dotData: const FlDotData(show: false),
            color: const Color(0xFF34D399),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF34D399).withOpacity(0.35),
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
            color: Colors.white.withOpacity(0.25),
            dashArray: [6, 4],
          ),
          HorizontalLine(
            y: 2200,
            color: Colors.white.withOpacity(0.25),
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
        gridData: FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        barGroups: [
          for (var i = 0; i < entries.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: entries[i].value.toDouble(),
                  width: 12,
                  color: const Color(0xFF38BDF8),
                  borderRadius: BorderRadius.circular(6),
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
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: [
          PieChartSectionData(value: dry, color: const Color(0xFFF97316), showTitle: false),
          PieChartSectionData(value: optimal, color: const Color(0xFF10B981), showTitle: false),
          PieChartSectionData(value: wet, color: const Color(0xFF0EA5E9), showTitle: false),
        ],
      ),
    );
  }
}

Widget _empty(String label) {
  return Center(
    child: Text(
      label,
      style: const TextStyle(color: Colors.white60),
    ),
  );
}

