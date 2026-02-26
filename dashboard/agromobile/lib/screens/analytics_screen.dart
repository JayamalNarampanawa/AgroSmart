import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/sensor_data.dart';
import '../services/firebase_service.dart';
import '../widgets/glass_card.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Analytics'),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF050A14),
              Color(0xFF0B1221),
              Color(0xFF050A14),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: StreamBuilder<List<SensorData>>(
            stream: FirebaseService.instance.historyStream(limit: 50),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final history = snapshot.data ?? [];

              if (history.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.analytics_outlined,
                          size: 64, color: Colors.white.withOpacity(0.3)),
                      const SizedBox(height: 16),
                      Text(
                        'No history data yet',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5), fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary Stats
                    _SummaryRow(history: history),
                    const SizedBox(height: 24),

                    // Temperature Chart
                    _SectionTitle(title: 'Temperature'),
                    const SizedBox(height: 12),
                    _TrendChart(
                      history: history,
                      getValue: (d) => d.temperature,
                      color: const Color(0xFFFFA726),
                      unit: '\u00B0C',
                    ),
                    const SizedBox(height: 24),

                    // Humidity Chart
                    _SectionTitle(title: 'Humidity'),
                    const SizedBox(height: 12),
                    _TrendChart(
                      history: history,
                      getValue: (d) => d.humidity,
                      color: const Color(0xFF00E5FF),
                      unit: '%',
                    ),
                    const SizedBox(height: 24),

                    // Soil Moisture Chart
                    _SectionTitle(title: 'Soil Moisture'),
                    const SizedBox(height: 12),
                    _TrendChart(
                      history: history,
                      getValue: (d) => d.soilMoisture,
                      color: const Color(0xFF00FFC2),
                      unit: '',
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── Summary row ──────────────────────────────────────────────────────────────

class _SummaryRow extends StatelessWidget {
  final List<SensorData> history;
  const _SummaryRow({required this.history});

  @override
  Widget build(BuildContext context) {
    final temps = history.where((d) => d.temperature != null).toList();
    final humids = history.where((d) => d.humidity != null).toList();
    final soils = history.where((d) => d.soilMoisture != null).toList();

    final avgTemp = temps.isEmpty
        ? '--'
        : (temps.fold<double>(0, (s, d) => s + d.temperature!) / temps.length)
            .toStringAsFixed(1);
    final avgHumid = humids.isEmpty
        ? '--'
        : (humids.fold<double>(0, (s, d) => s + d.humidity!) / humids.length)
            .toStringAsFixed(1);
    final avgSoil = soils.isEmpty
        ? '--'
        : (soils.fold<double>(0, (s, d) => s + d.soilMoisture!) / soils.length)
            .toStringAsFixed(0);

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Avg Temp',
            value: '$avgTemp\u00B0',
            icon: Icons.thermostat,
            color: const Color(0xFFFFA726),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Avg Humidity',
            value: '$avgHumid%',
            icon: Icons.water_drop,
            color: const Color(0xFF00E5FF),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Avg Soil',
            value: avgSoil,
            icon: Icons.grass,
            color: const Color(0xFF00FFC2),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                  color: color, fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Section title ────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
    );
  }
}

// ── Trend chart card ─────────────────────────────────────────────────────────

class _TrendChart extends StatelessWidget {
  final List<SensorData> history;
  final double? Function(SensorData) getValue;
  final Color color;
  final String unit;

  const _TrendChart({
    required this.history,
    required this.getValue,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    final points = <FlSpot>[];
    double minY = double.infinity;
    double maxY = double.negativeInfinity;

    for (var i = 0; i < history.length; i++) {
      final v = getValue(history[i]);
      if (v == null) continue;
      points.add(FlSpot(i.toDouble(), v));
      minY = math.min(minY, v);
      maxY = math.max(maxY, v);
    }

    if (points.isEmpty) {
      return GlassCard(
        child: SizedBox(
          height: 140,
          child: Center(
            child: Text('No data',
                style: TextStyle(color: Colors.white.withOpacity(0.4))),
          ),
        ),
      );
    }

    // Add some padding to y-axis range
    final range = maxY - minY;
    final padY = range < 1 ? 1.0 : range * 0.15;

    // Compute current, min, max for the footer
    final current = points.last.y;
    final timeFormat = DateFormat('HH:mm');

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Chart
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                minY: minY - padY,
                maxY: maxY + padY,
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 24,
                      interval:
                          math.max(1, (points.length / 5).floorToDouble()),
                      getTitlesWidget: (value, meta) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= history.length) {
                          return const SizedBox.shrink();
                        }
                        return Text(
                          timeFormat.format(history[idx].timestamp),
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 9),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                              color: Colors.white30, fontSize: 10),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Colors.white.withOpacity(0.04),
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: points,
                    isCurved: true,
                    color: color,
                    barWidth: 2.5,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          color.withOpacity(0.25),
                          color.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Min / Current / Max footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MiniStat(
                  label: 'Min',
                  value: '${minY.toStringAsFixed(1)}$unit',
                  color: Colors.white54),
              _MiniStat(
                  label: 'Current',
                  value: '${current.toStringAsFixed(1)}$unit',
                  color: color),
              _MiniStat(
                  label: 'Max',
                  value: '${maxY.toStringAsFixed(1)}$unit',
                  color: Colors.white54),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _MiniStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: color, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label,
            style: const TextStyle(color: Colors.white38, fontSize: 10)),
      ],
    );
  }
}
