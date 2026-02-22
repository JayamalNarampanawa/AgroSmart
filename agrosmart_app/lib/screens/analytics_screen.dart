import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/firebase_service.dart';
import '../models/sensor_history.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            _AnalyticsAppBar(tabController: _tabs),
            Expanded(
              child: StreamBuilder<List<SensorHistory>>(
                stream: FirebaseService().historyStream(limit: 60),
                builder: (context, snapshot) {
                  final data = snapshot.data ?? [];
                  return TabBarView(
                    controller: _tabs,
                    children: [
                      _TemperatureTab(history: data),
                      _SoilMoistureTab(history: data),
                      _IrrigationTab(history: data),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsAppBar extends StatelessWidget {
  final TabController tabController;
  const _AnalyticsAppBar({required this.tabController});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF060d1a),
        border: Border(
          bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
      ),
      child: Column(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.chartLine,
                  size: 16,
                  color: AppTheme.accent1,
                ),
                SizedBox(width: 10),
                Text(
                  'Analytics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.heading,
                  ),
                ),
                Spacer(),
                Text(
                  'Last 60 readings',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          TabBar(
            controller: tabController,
            labelColor: AppTheme.accent1,
            unselectedLabelColor: AppTheme.textMuted,
            indicatorColor: AppTheme.accent1,
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            tabs: const [
              Tab(text: 'Temperature'),
              Tab(text: 'Soil Moisture'),
              Tab(text: 'Irrigation'),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Temperature tab ──────────────────────────────────────────────────────────
class _TemperatureTab extends StatelessWidget {
  final List<SensorHistory> history;
  const _TemperatureTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final spots = history.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value.temperature);
    }).toList();

    final minVal = history
        .map((e) => e.temperature)
        .reduce((a, b) => a < b ? a : b);
    final maxVal = history
        .map((e) => e.temperature)
        .reduce((a, b) => a > b ? a : b);
    final avgVal =
        history.fold(0.0, (s, e) => s + e.temperature) / history.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI row
          Row(
            children: [
              _StatChip(
                label: 'Min',
                value: '${minVal.toStringAsFixed(1)}°C',
                color: AppTheme.accent3,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Avg',
                value: '${avgVal.toStringAsFixed(1)}°C',
                color: const Color(0xFFfb7185),
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Max',
                value: '${maxVal.toStringAsFixed(1)}°C',
                color: AppTheme.warning,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Line chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Temperature Over Time',
                  subtitle: 'Real-time sensor readings',
                  icon: FontAwesomeIcons.thermometerHalf,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 5,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: AppTheme.glassBorder, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              v.toInt().toString(),
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (history.length / 5).ceilToDouble(),
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= history.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                DateFormat(
                                  'HH:mm',
                                ).format(history[idx].timestamp),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: const Color(0xFFfb7185),
                          barWidth: 2.5,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, _, __, idx) {
                              if (idx == spots.length - 1) {
                                return FlDotCirclePainter(
                                  radius: 5,
                                  color: const Color(0xFFfb7185),
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              }
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeWidth: 0,
                                strokeColor: Colors.transparent,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: const Color(0xFFfb7185).withOpacity(0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Current vs ideal bar chart
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Temperature & Humidity',
                  subtitle: 'Latest readings comparison',
                  icon: FontAwesomeIcons.chartBar,
                ),
                const SizedBox(height: 20),
                _TempHumidityBarChart(history: history),
              ],
            ),
          ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
        ],
      ),
    );
  }
}

class _TempHumidityBarChart extends StatelessWidget {
  final List<SensorHistory> history;
  const _TempHumidityBarChart({required this.history});

  @override
  Widget build(BuildContext context) {
    final last10 = history.length > 10
        ? history.sublist(history.length - 10)
        : history;

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          backgroundColor: Colors.transparent,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppTheme.glassBorder, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, _) {
                  final idx = v.toInt();
                  if (idx < 0 || idx >= last10.length) {
                    return const SizedBox.shrink();
                  }
                  return Text(
                    DateFormat('HH:mm').format(last10[idx].timestamp),
                    style: const TextStyle(
                      fontSize: 8,
                      color: AppTheme.textMuted,
                    ),
                  );
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (v, _) => Text(
                  v.toInt().toString(),
                  style: const TextStyle(
                    fontSize: 9,
                    color: AppTheme.textMuted,
                  ),
                ),
              ),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          barGroups: last10.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.temperature,
                  color: const Color(0xFFfb7185),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                BarChartRodData(
                  toY: e.value.humidity,
                  color: AppTheme.accent3.withOpacity(0.7),
                  width: 8,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─── Soil Moisture tab ────────────────────────────────────────────────────────
class _SoilMoistureTab extends StatelessWidget {
  final List<SensorHistory> history;
  const _SoilMoistureTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Text(
          'No data available',
          style: TextStyle(color: AppTheme.textMuted),
        ),
      );
    }

    final wetnessValues = history.map((h) => h.soilWetnessPercent()).toList();
    final avgWet =
        wetnessValues.fold(0.0, (s, v) => s + v) / wetnessValues.length;
    final minWet = wetnessValues.reduce((a, b) => a < b ? a : b);
    final maxWet = wetnessValues.reduce((a, b) => a > b ? a : b);

    final spots = wetnessValues.asMap().entries.map((e) {
      return FlSpot(e.key.toDouble(), e.value);
    }).toList();

    // Ideal range band (30–75%)
    final idealSpots = List.generate(
      history.length,
      (i) => FlSpot(i.toDouble(), 75),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatChip(
                label: 'Min',
                value: '${minWet.toStringAsFixed(0)}%',
                color: AppTheme.warning,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Avg',
                value: '${avgWet.toStringAsFixed(0)}%',
                color: AppTheme.accent2,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Max',
                value: '${maxWet.toStringAsFixed(0)}%',
                color: AppTheme.accent3,
              ),
            ],
          ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Soil Moisture Trend',
                  subtitle: 'Wetness % — ideal range: 30–75%',
                  icon: FontAwesomeIcons.droplet,
                ),
                const SizedBox(height: 8),
                // Legend
                Row(
                  children: [
                    const _ChartLegend(color: AppTheme.accent2, label: 'Actual'),
                    const SizedBox(width: 16),
                    _ChartLegend(
                      color: AppTheme.accent1.withOpacity(0.4),
                      label: 'Ideal max (75%)',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minY: 0,
                      maxY: 100,
                      backgroundColor: Colors.transparent,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (_) =>
                            const FlLine(color: AppTheme.glassBorder, strokeWidth: 1),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              '${v.toInt()}%',
                              style: const TextStyle(
                                fontSize: 9,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: (history.length / 5).ceilToDouble(),
                            getTitlesWidget: (v, _) {
                              final idx = v.toInt();
                              if (idx < 0 || idx >= history.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                DateFormat(
                                  'HH:mm',
                                ).format(history[idx].timestamp),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      lineBarsData: [
                        // Actual line
                        LineChartBarData(
                          spots: spots,
                          isCurved: true,
                          curveSmoothness: 0.35,
                          color: AppTheme.accent2,
                          barWidth: 2.5,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppTheme.accent2.withOpacity(0.25),
                                AppTheme.accent2.withOpacity(0.01),
                              ],
                            ),
                          ),
                        ),
                        // Ideal max line
                        LineChartBarData(
                          spots: idealSpots,
                          isCurved: false,
                          color: AppTheme.accent1.withOpacity(0.3),
                          barWidth: 1.5,
                          dashArray: [6, 4],
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(show: false),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),
        ],
      ),
    );
  }
}

// ─── Irrigation tab ───────────────────────────────────────────────────────────
class _IrrigationTab extends StatelessWidget {
  final List<SensorHistory> history;
  const _IrrigationTab({required this.history});

  @override
  Widget build(BuildContext context) {
    // Aggregate pump ON count by day
    final Map<String, int> byDay = {};
    for (final rec in history) {
      if (rec.pumpStatus) {
        final key = DateFormat('MM/dd').format(rec.timestamp);
        byDay[key] = (byDay[key] ?? 0) + 1;
      }
    }

    final days = byDay.keys.toList();
    final counts = days.map((d) => byDay[d]!.toDouble()).toList();

    final pumpOnCount = history.where((h) => h.pumpStatus).length;
    final pumpOnPct = history.isEmpty
        ? 0.0
        : pumpOnCount / history.length * 100;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatChip(
                label: 'Pump ON',
                value: '$pumpOnCount',
                color: AppTheme.accent1,
              ),
              const SizedBox(width: 8),
              _StatChip(
                label: 'Active %',
                value: '${pumpOnPct.toStringAsFixed(0)}%',
                color: AppTheme.accent2,
              ),
            ],
          ),
          const SizedBox(height: 16),

          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Irrigation Activity',
                  subtitle: 'Pump ON count per day',
                  icon: FontAwesomeIcons.faucet,
                ),
                const SizedBox(height: 20),
                if (days.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No pump activity recorded yet',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      BarChartData(
                        backgroundColor: Colors.transparent,
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (_) => const FlLine(
                            color: AppTheme.glassBorder,
                            strokeWidth: 1,
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (v, _) {
                                final idx = v.toInt();
                                if (idx < 0 || idx >= days.length) {
                                  return const SizedBox.shrink();
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    days[idx],
                                    style: const TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.textMuted,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 24,
                              getTitlesWidget: (v, _) => Text(
                                v.toInt().toString(),
                                style: const TextStyle(
                                  fontSize: 9,
                                  color: AppTheme.textMuted,
                                ),
                              ),
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        barGroups: days.asMap().entries.map((e) {
                          return BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: counts[e.key],
                                gradient: const LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [AppTheme.accent1, AppTheme.accent5],
                                ),
                                width: 28,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(6),
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 16),

          // Pie chart: pump on vs off
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Pump On/Off Ratio',
                  subtitle: 'Across all recorded readings',
                  icon: FontAwesomeIcons.chartPie,
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 3,
                          centerSpaceRadius: 40,
                          sections: [
                            PieChartSectionData(
                              value: pumpOnPct,
                              color: AppTheme.accent1,
                              radius: 28,
                              title: '${pumpOnPct.toStringAsFixed(0)}%',
                              titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            PieChartSectionData(
                              value: 100 - pumpOnPct,
                              color: AppTheme.glassBorder,
                              radius: 24,
                              title: '',
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LegendDot(
                          color: AppTheme.accent1,
                          label: 'Pump ON',
                          value: '$pumpOnCount readings',
                        ),
                        const SizedBox(height: 10),
                        _LegendDot(
                          color: AppTheme.textMuted,
                          label: 'Pump OFF',
                          value: '${history.length - pumpOnCount} readings',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
        ],
      ),
    );
  }
}

// ─── Helper widgets ────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: AppTheme.glassDeco(
          borderColor: color.withOpacity(0.2),
          gradientColors: [color.withOpacity(0.08), AppTheme.cardBg],
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  final Color color;
  final String label;
  const _ChartLegend({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 3,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  const _LegendDot({
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ),
      ],
    );
  }
}
