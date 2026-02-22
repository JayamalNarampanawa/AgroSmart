import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../services/app_state.dart';
import '../services/firebase_service.dart';
import '../models/sensor_history.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import '../widgets/common_widgets.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            _AppBar(),
            Expanded(
              child: RefreshIndicator(
                color: AppTheme.accent1,
                backgroundColor: AppTheme.cardBg,
                onRefresh: () async {
                  await Future.delayed(const Duration(milliseconds: 500));
                },
                child: const SingleChildScrollView(
                  physics: AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _AlertsBanner(),
                      SizedBox(height: 16),
                      _SensorGrid(),
                      SizedBox(height: 20),
                      _KPIRow(),
                      SizedBox(height: 20),
                      _SmartInsightsCard(),
                      SizedBox(height: 20),
                      _RecentActivityCard(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── App Bar ─────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Color(0xFF060d1a),
        border: Border(
          bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Logo + title
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: FaIcon(
                FontAwesomeIcons.seedling,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AgroSmart',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.heading,
                ),
              ),
              Text(
                'Smart Farm Dashboard',
                style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
              ),
            ],
          ),
          const Spacer(),
          LivePill(isLive: state.isLive),
        ],
      ),
    );
  }
}

// ─── Alerts Banner ─────────────────────────────────────────────────────────
class _AlertsBanner extends StatelessWidget {
  const _AlertsBanner();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sensor = state.sensor;
    if (sensor == null) return const SizedBox.shrink();

    final alerts = <_Alert>[];
    final wetness = sensor.soilWetnessPercent();

    if (wetness < 25) {
      alerts.add(
        _Alert(
          icon: FontAwesomeIcons.droplet,
          message:
              'Soil critically dry (${wetness.toStringAsFixed(0)}%) — Irrigation needed',
          color: AppTheme.danger,
        ),
      );
    }
    if (sensor.hasHeatRisk) {
      alerts.add(
        _Alert(
          icon: FontAwesomeIcons.temperatureHigh,
          message:
              'Heat stress risk — ${sensor.temperature.toStringAsFixed(1)}°C',
          color: AppTheme.warning,
        ),
      );
    }
    if (sensor.hasLowLight) {
      alerts.add(
        _Alert(
          icon: FontAwesomeIcons.cloudSun,
          message:
              'Low light conditions — ${sensor.lightLevel.toStringAsFixed(0)} lux',
          color: AppTheme.accent3,
        ),
      );
    }

    if (alerts.isEmpty) return const SizedBox.shrink();

    return Column(children: alerts.map((a) => _AlertTile(alert: a)).toList());
  }
}

class _Alert {
  final IconData icon;
  final String message;
  final Color color;
  const _Alert({
    required this.icon,
    required this.message,
    required this.color,
  });
}

class _AlertTile extends StatelessWidget {
  final _Alert alert;
  const _AlertTile({required this.alert});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: alert.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: alert.color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          FaIcon(alert.icon, size: 14, color: alert.color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              alert.message,
              style: TextStyle(
                fontSize: 12,
                color: alert.color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.05, end: 0);
  }
}

// ─── Sensor Grid ─────────────────────────────────────────────────────────────
class _SensorGrid extends StatelessWidget {
  const _SensorGrid();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sensor = state.sensor;
    final loading = state.loading;

    if (loading) {
      return GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: List.generate(4, (_) => const ShimmerBox(height: 100)),
      );
    }

    final wetness = sensor?.soilWetnessPercent() ?? 0.0;

    final cards = [
      SensorCard(
        label: 'Temperature',
        value: sensor != null ? sensor.temperature.toStringAsFixed(1) : '--',
        unit: '°C',
        icon: FontAwesomeIcons.temperatureHalf,
        color: const Color(0xFFfb7185),
        subtitle: sensor != null
            ? (sensor.temperature > 35
                ? 'Heat Risk'
                : sensor.temperature < 15
                    ? 'Cold'
                    : 'Normal')
            : null,
        progressValue:
            sensor != null ? (sensor.temperature / 50).clamp(0, 1) : null,
      ),
      SensorCard(
        label: 'Humidity',
        value: sensor != null ? sensor.humidity.toStringAsFixed(1) : '--',
        unit: '%',
        icon: FontAwesomeIcons.wind,
        color: AppTheme.accent3,
        subtitle: sensor != null
            ? (sensor.humidity > 80
                ? 'High'
                : sensor.humidity < 30
                    ? 'Low'
                    : 'Optimal')
            : null,
        progressValue:
            sensor != null ? (sensor.humidity / 100).clamp(0, 1) : null,
      ),
      SensorCard(
        label: 'Soil Moisture',
        value: sensor != null ? wetness.toStringAsFixed(0) : '--',
        unit: '%',
        icon: FontAwesomeIcons.droplet,
        color: AppTheme.accent2,
        subtitle: sensor?.soilStatus,
        progressValue: sensor != null ? (wetness / 100).clamp(0, 1) : null,
      ),
      SensorCard(
        label: 'Light Level',
        value: sensor != null ? sensor.lightLevel.toStringAsFixed(0) : '--',
        unit: 'lux',
        icon: FontAwesomeIcons.sun,
        color: const Color(0xFFfbbf24),
        subtitle: sensor != null
            ? (sensor.lightLevel > 2000
                ? 'Bright'
                : sensor.lightLevel < 500
                    ? 'Low'
                    : 'Moderate')
            : null,
        progressValue:
            sensor != null ? (sensor.lightLevel / 5000).clamp(0, 1) : null,
      ),
      SensorCard(
        label: 'Pump Status',
        value: sensor != null ? (sensor.pumpStatus ? 'ON' : 'OFF') : '--',
        unit: '',
        icon: FontAwesomeIcons.faucet,
        color: AppTheme.accent1,
        isPumpCard: true,
      ),
      _LastUpdateCard(lastUpdated: state.lastUpdated),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: cards,
    );
  }
}

class _LastUpdateCard extends StatelessWidget {
  final DateTime? lastUpdated;
  const _LastUpdateCard({this.lastUpdated});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const FaIcon(
            FontAwesomeIcons.clock,
            size: 14,
            color: AppTheme.textMuted,
          ),
          const SizedBox(height: 10),
          const Text(
            'Last Update',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 4),
          Text(
            lastUpdated != null
                ? DateFormat('HH:mm:ss').format(lastUpdated!)
                : '--:--:--',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
              fontFamily: 'SpaceMono',
            ),
          ),
          const SizedBox(height: 2),
          Text(
            lastUpdated != null
                ? DateFormat('MMM dd, yyyy').format(lastUpdated!)
                : 'No data',
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── KPI Row ─────────────────────────────────────────────────────────────────
class _KPIRow extends StatelessWidget {
  const _KPIRow();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SensorHistory>>(
      stream: FirebaseService().historyStream(limit: 100),
      builder: (context, snapshot) {
        final data = snapshot.data ?? [];
        if (data.isEmpty) return const SizedBox.shrink();

        final temps = data.map((d) => d.temperature).toList();
        final maxTemp = temps.reduce((a, b) => a > b ? a : b);
        final minTemp = temps.reduce((a, b) => a < b ? a : b);
        final avgTemp = temps.fold(0.0, (a, b) => a + b) / temps.length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Temperature KPIs',
              subtitle: 'Based on recent readings',
              icon: FontAwesomeIcons.chartBar,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _KPICard(
                    label: 'Avg',
                    value: avgTemp.toStringAsFixed(1),
                    unit: '°C',
                    color: const Color(0xFFfb7185),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KPICard(
                    label: 'High',
                    value: maxTemp.toStringAsFixed(1),
                    unit: '°C',
                    color: AppTheme.warning,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _KPICard(
                    label: 'Low',
                    value: minTemp.toStringAsFixed(1),
                    unit: '°C',
                    color: AppTheme.accent3,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _KPICard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _KPICard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: AppTheme.glassDeco(
        borderColor: color.withOpacity(0.2),
        gradientColors: [color.withOpacity(0.08), AppTheme.cardBg],
      ),
      child: Column(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}

// ─── Smart Insights Card ──────────────────────────────────────────────────
class _SmartInsightsCard extends StatelessWidget {
  const _SmartInsightsCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sensor = state.sensor;
    final insight = state.insight;

    final soilStatus = insight?.soilStatus ?? sensor?.soilStatus ?? 'Unknown';
    final irrigAdv =
        insight?.irrigationAdvice ?? sensor?.irrigationAdvice ?? 'OFF';
    final heatRisk = insight?.heatRisk ?? (sensor?.hasHeatRisk ?? false);
    final lowLight = insight?.lowLight ?? (sensor?.hasLowLight ?? false);

    final irrigOn = irrigAdv == 'ON';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Smart Insights',
            subtitle: 'Real-time recommendations',
            icon: FontAwesomeIcons.brain,
          ),
          const SizedBox(height: 16),
          _InsightRow(
            icon: FontAwesomeIcons.droplet,
            label: 'Soil Status',
            value: soilStatus,
            color: soilStatus == 'Dry'
                ? AppTheme.warning
                : soilStatus == 'Wet'
                    ? AppTheme.accent3
                    : AppTheme.accent2,
          ),
          const SizedBox(height: 10),
          _InsightRow(
            icon: FontAwesomeIcons.faucet,
            label: 'Irrigation',
            value: irrigAdv,
            color: irrigOn ? AppTheme.accent1 : AppTheme.textMuted,
            badge: irrigOn,
          ),
          if (heatRisk) ...[
            const SizedBox(height: 10),
            const _InsightRow(
              icon: FontAwesomeIcons.temperatureHigh,
              label: 'Heat Risk',
              value: 'Active',
              color: AppTheme.danger,
              badge: true,
            ),
          ],
          if (lowLight) ...[
            const SizedBox(height: 10),
            const _InsightRow(
              icon: FontAwesomeIcons.cloudSun,
              label: 'Light Level',
              value: 'Low',
              color: AppTheme.warning,
            ),
          ],
          if (insight?.summary != null && insight!.summary.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.accent1.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.accent1.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const FaIcon(
                    FontAwesomeIcons.circleInfo,
                    size: 12,
                    color: AppTheme.accent1,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight.summary,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool badge;

  const _InsightRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.badge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        FaIcon(icon, size: 13, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary),
          ),
        ),
        StatusBadge(label: value, color: color),
      ],
    );
  }
}

// ─── Recent Activity ──────────────────────────────────────────────────────
class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<SensorHistory>>(
      stream: FirebaseService().historyStream(limit: 10),
      builder: (context, snapshot) {
        final history = snapshot.data ?? [];

        return GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(
                title: 'Recent Readings',
                subtitle: 'Last 10 sensor logs',
                icon: FontAwesomeIcons.listUl,
              ),
              const SizedBox(height: 14),
              if (history.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'No history data yet',
                      style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
                    ),
                  ),
                )
              else
                ...history.reversed
                    .take(8)
                    .map((rec) => _HistoryTile(rec: rec)),
            ],
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final SensorHistory rec;
  const _HistoryTile({required this.rec});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.glassBorder.withOpacity(0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.glassBorder, width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: rec.pumpStatus ? AppTheme.accent2 : AppTheme.textMuted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${rec.temperature.toStringAsFixed(1)}°C  ·  '
              '${rec.humidity.toStringAsFixed(0)}%  ·  '
              '${rec.soilWetnessPercent().toStringAsFixed(0)}% soil',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Text(
            DateFormat('HH:mm').format(rec.timestamp),
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textMuted,
              fontFamily: 'SpaceMono',
            ),
          ),
        ],
      ),
    );
  }
}
