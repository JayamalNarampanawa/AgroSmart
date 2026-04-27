import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/weather_now.dart';
import '../services/firebase_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/insight_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class WeatherScreen extends StatelessWidget {
  const WeatherScreen({super.key});

  static const double _lat = 7.3;
  static const double _lon = 80.64;
  static const String _owmKey = '7085554067dbfdcfcb40ac08a6ae1a23';

  Future<void> _refreshWeather(BuildContext context) async {
    try {
      await FirebaseService.instance.refreshWeatherFromOpenWeather(
        lat: _lat,
        lon: _lon,
        apiKey: _owmKey,
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Weather updated from OpenWeather'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Refresh failed: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: FirebaseService.instance.weatherStream(),
        builder: (context, snapshot) {
          final weather =
              snapshot.data == null ? null : WeatherNow.fromMap(snapshot.data!);
          final updated = weather?.updatedAt == null
              ? 'Live greenhouse weather'
              : 'Updated ${DateFormat('MMM d, h:mm a').format(weather!.updatedAt!)}';

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xxl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DashboardHeader(
                  greeting: 'Weather',
                  subtitle: updated,
                  avatarText: 'W',
                  trailing: IconButton.filledTonal(
                    onPressed: () => _refreshWeather(context),
                    icon: const Icon(Icons.refresh_rounded),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                if (snapshot.connectionState == ConnectionState.waiting &&
                    weather == null)
                  const _WeatherSkeleton()
                else if (weather == null)
                  EmptyStateWidget(
                    icon: Icons.cloud_off_rounded,
                    title: 'No weather data yet',
                    subtitle:
                        'Refresh weather to pull the latest field conditions.',
                    actionLabel: 'Refresh Weather',
                    onAction: () => _refreshWeather(context),
                  )
                else ...[
                  _WeatherHero(weather: weather),
                  const SizedBox(height: AppSpacing.xxl),
                  const SectionHeader(
                    title: 'Field Conditions',
                    subtitle: 'Current weather factors for crop decisions',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeatherMetricTile(
                    icon: Icons.thermostat_rounded,
                    title: 'Temperature',
                    value: '${weather.temperature.toStringAsFixed(1)}\u00B0C',
                    subtitle: _temperatureLabel(weather.temperature),
                    color: AppColors.accentRose,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeatherMetricTile(
                    icon: Icons.water_drop_rounded,
                    title: 'Humidity',
                    value: '${weather.humidity.toStringAsFixed(0)}%',
                    subtitle: _humidityLabel(weather.humidity),
                    color: AppColors.accentCyan,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeatherMetricTile(
                    icon: Icons.air_rounded,
                    title: 'Wind Speed',
                    value: '${weather.windSpeed.toStringAsFixed(1)} m/s',
                    subtitle: weather.windSpeed > 8
                        ? 'Strong movement'
                        : 'Stable airflow',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _WeatherMetricTile(
                    icon: Icons.thunderstorm_rounded,
                    title: 'Rainfall',
                    value: '${weather.rainfall.toStringAsFixed(1)} mm',
                    subtitle: weather.rainfall > 0
                        ? 'Natural watering active'
                        : 'No recent rain',
                    color: AppColors.accentGreen,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  const SectionHeader(
                    title: 'Weather Insight',
                    subtitle: 'Quick guidance for farm operation',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  InsightCard(
                    icon: _insightIcon(weather),
                    title: _insightTitle(weather),
                    subtitle: _insightMessage(weather),
                    badge: _insightBadge(weather),
                    tone: _insightTone(weather),
                    color: _insightColor(weather),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AlertCard(
                    icon: Icons.public_rounded,
                    title: weather.source ?? 'Weather source',
                    message:
                        'Location set to Kurunegala region coordinates. Refresh pulls the latest OpenWeather values into Firebase.',
                    color: AppColors.primary,
                    tone: StatusBadgeTone.info,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                  _WeatherHistory(weatherNode: snapshot.data!),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  static String _temperatureLabel(double value) {
    if (value >= 34) return 'Heat stress watch';
    if (value <= 18) return 'Cooler than usual';
    return 'Crop-friendly range';
  }

  static String _humidityLabel(double value) {
    if (value >= 85) return 'Fungal risk watch';
    if (value <= 45) return 'Dry air';
    return 'Balanced humidity';
  }

  static IconData _insightIcon(WeatherNow weather) {
    if (weather.rainfall > 0) return Icons.umbrella_rounded;
    if (weather.temperature >= 34) return Icons.local_fire_department_rounded;
    if (weather.humidity >= 85) return Icons.coronavirus_rounded;
    return Icons.eco_rounded;
  }

  static String _insightTitle(WeatherNow weather) {
    if (weather.rainfall > 0) return 'Rain may reduce irrigation need';
    if (weather.temperature >= 34) return 'Heat stress risk';
    if (weather.humidity >= 85) return 'High humidity detected';
    return 'Conditions look stable';
  }

  static String _insightMessage(WeatherNow weather) {
    if (weather.rainfall > 0) {
      return 'Delay manual irrigation until soil moisture drops again.';
    }
    if (weather.temperature >= 34) {
      return 'Check soil moisture more often and avoid midday stress.';
    }
    if (weather.humidity >= 85) {
      return 'Improve airflow and inspect leaves for disease pressure.';
    }
    return 'Current weather supports normal irrigation and monitoring.';
  }

  static String _insightBadge(WeatherNow weather) {
    if (weather.rainfall > 0) return 'Rain';
    if (weather.temperature >= 34 || weather.humidity >= 85) return 'Watch';
    return 'Stable';
  }

  static StatusBadgeTone _insightTone(WeatherNow weather) {
    if (weather.temperature >= 34 || weather.humidity >= 85) {
      return StatusBadgeTone.warning;
    }
    return StatusBadgeTone.success;
  }

  static Color _insightColor(WeatherNow weather) {
    if (weather.rainfall > 0) return AppColors.accentCyan;
    if (weather.temperature >= 34) return AppColors.accentOrange;
    if (weather.humidity >= 85) return AppColors.accentRose;
    return AppColors.accentGreen;
  }
}

class _WeatherHero extends StatelessWidget {
  final WeatherNow weather;

  const _WeatherHero({required this.weather});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final rawDescription = weather.description ?? 'Current weather';
    final description = rawDescription.trim().isEmpty
        ? 'Current weather'
        : rawDescription.trim();
    final formattedDescription =
        description[0].toUpperCase() + description.substring(1);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0EA5E9), Color(0xFF6D5DF6)],
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.accentCyan),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.20),
                  ),
                ),
                child: const Icon(
                  Icons.cloud_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: weather.source ?? 'Live',
                icon: Icons.wifi_tethering_rounded,
                tone: StatusBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${weather.temperature.toStringAsFixed(1)}\u00B0C',
              style: theme.displayLarge?.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            formattedDescription,
            style: theme.titleMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroChip(
                icon: Icons.water_drop_rounded,
                label: '${weather.humidity.toStringAsFixed(0)}% humidity',
              ),
              _HeroChip(
                icon: Icons.air_rounded,
                label: '${weather.windSpeed.toStringAsFixed(1)} m/s wind',
              ),
              _HeroChip(
                icon: Icons.thunderstorm_rounded,
                label: '${weather.rainfall.toStringAsFixed(1)} mm rain',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _HeroChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _WeatherMetricTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;

  const _WeatherMetricTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: Icon(icon, color: color, size: 25),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.bodyMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(value, style: theme.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle, style: theme.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherHistory extends StatelessWidget {
  final Map<String, dynamic> weatherNode;

  const _WeatherHistory({required this.weatherNode});

  @override
  Widget build(BuildContext context) {
    final history = weatherNode['history'];
    final entries = history is Map
        ? history.values
            .whereType<Map>()
            .map((item) => Map<String, dynamic>.from(item))
            .toList()
        : <Map<String, dynamic>>[];

    if (entries.isEmpty) {
      return const AlertCard(
        icon: Icons.history_rounded,
        title: 'No weather history yet',
        message:
            'Refresh weather over time to build previous weather snapshots in Firebase.',
        color: AppColors.accentOrange,
        tone: StatusBadgeTone.warning,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Previous Weather',
          subtitle: 'Recent records stored under Firebase weather history',
        ),
        const SizedBox(height: AppSpacing.md),
        ...entries.take(5).map((item) {
          final weather = WeatherNow.fromMap(item);
          final updated = weather.updatedAt == null
              ? 'Saved record'
              : DateFormat('MMM d, h:mm a').format(weather.updatedAt!);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: SoftWhiteCard(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.accentCyan.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.chip),
                    ),
                    child: const Icon(
                      Icons.cloud_queue_rounded,
                      color: AppColors.accentCyan,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(updated,
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${weather.temperature.toStringAsFixed(1)}\u00B0C, ${weather.humidity.toStringAsFixed(0)}% humidity, ${weather.rainfall.toStringAsFixed(1)} mm rain',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _WeatherSkeleton extends StatelessWidget {
  const _WeatherSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SoftWhiteCard(
          child: SizedBox(height: 180),
        ),
        SizedBox(height: AppSpacing.md),
        SoftWhiteCard(
          child: SizedBox(height: 86),
        ),
        SizedBox(height: AppSpacing.md),
        SoftWhiteCard(
          child: SizedBox(height: 86),
        ),
      ],
    );
  }
}
