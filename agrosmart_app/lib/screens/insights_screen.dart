import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF060d1a),
                border: Border(
                  bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
                ),
              ),
              child: const Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.brain,
                    size: 16,
                    color: AppTheme.accent1,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Smart Insights',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.heading,
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CropSuitabilityCard(),
                    SizedBox(height: 16),
                    _RecommendationCard(),
                    SizedBox(height: 16),
                    _EnvironmentStatusCard(),
                    SizedBox(height: 16),
                    _InsightTipsCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Crop suitability ─────────────────────────────────────────────────────────
class _CropSuitabilityCard extends StatelessWidget {
  const _CropSuitabilityCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final suit = state.suitability;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Crop Suitability',
            subtitle: 'AI-scored compatibility for current conditions',
            icon: FontAwesomeIcons.seedling,
          ),
          const SizedBox(height: 16),
          if (suit == null)
            const _NoDataPlaceholder(message: 'Suitability data loading...')
          else ...[
            ...suit.scores.entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SuitabilityBar(
                  cropName: _formatCropName(e.key),
                  score: e.value,
                  isTop: e.key == suit.topCrop,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const FaIcon(
                  FontAwesomeIcons.circleInfo,
                  size: 11,
                  color: AppTheme.textMuted,
                ),
                const SizedBox(width: 6),
                Text(
                  'Basis: ${suit.basis}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  String _formatCropName(String id) {
    switch (id) {
      case 'kidneybeans':
        return 'Kidney Beans';
      case 'mungbean':
        return 'Mung Bean';
      case 'chickpea':
        return 'Chickpea';
      default:
        return id.replaceAll('_', ' ').replaceFirst(id[0], id[0].toUpperCase());
    }
  }
}

class _SuitabilityBar extends StatelessWidget {
  final String cropName;
  final double score;
  final bool isTop;

  const _SuitabilityBar({
    required this.cropName,
    required this.score,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    final color = isTop ? AppTheme.accent2 : AppTheme.accent3.withOpacity(0.7);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(
                    cropName,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isTop ? FontWeight.w600 : FontWeight.w400,
                      color: isTop ? AppTheme.heading : AppTheme.textSecondary,
                    ),
                  ),
                  if (isTop) ...[
                    const SizedBox(width: 6),
                    const StatusBadge(
                        label: 'Best Match', color: AppTheme.accent2),
                  ],
                ],
              ),
            ),
            Text(
              '${score.toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearPercentIndicator(
          percent: (score / 100).clamp(0.0, 1.0),
          lineHeight: 6,
          backgroundColor: color.withOpacity(0.12),
          progressColor: color,
          padding: EdgeInsets.zero,
          barRadius: const Radius.circular(4),
          animation: true,
          animationDuration: 800,
        ),
      ],
    );
  }
}

// ─── Recommendation card ──────────────────────────────────────────────────────
class _RecommendationCard extends StatelessWidget {
  const _RecommendationCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final rec = state.recommendation;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Crop Recommendation',
            subtitle: 'Best match for your farm conditions',
            icon: FontAwesomeIcons.award,
          ),
          const SizedBox(height: 16),
          if (rec == null)
            const _NoDataPlaceholder(message: 'Recommendation loading...')
          else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AppTheme.glassDeco(
                borderColor: AppTheme.accent2.withOpacity(0.3),
                gradientColors: [
                  AppTheme.accent2.withOpacity(0.08),
                  AppTheme.cardBg,
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Center(
                      child: FaIcon(
                        FontAwesomeIcons.seedling,
                        size: 22,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatCrop(rec.bestCrop),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.heading,
                          ),
                        ),
                        Row(
                          children: [
                            StatusBadge(
                              label: rec.matchLevel,
                              color: rec.matchLevel == 'Good'
                                  ? AppTheme.accent2
                                  : rec.matchLevel == 'Moderate'
                                      ? AppTheme.warning
                                      : AppTheme.danger,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${rec.bestScore.toStringAsFixed(0)}% Match',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (rec.reasons.isNotEmpty) ...[
              const SizedBox(height: 14),
              const Text(
                'WHY THIS CROP',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textMuted,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              ...rec.reasons.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FaIcon(
                        FontAwesomeIcons.circleCheck,
                        size: 12,
                        color: AppTheme.accent2,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          r,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 100.ms);
  }

  String _formatCrop(String id) {
    switch (id) {
      case 'kidneybeans':
        return 'Kidney Beans';
      case 'mungbean':
        return 'Mung Bean';
      default:
        return id.replaceFirst(id[0], id[0].toUpperCase());
    }
  }
}

// ─── Environment status ───────────────────────────────────────────────────────
class _EnvironmentStatusCard extends StatelessWidget {
  const _EnvironmentStatusCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sensor = state.sensor;
    if (sensor == null) return const SizedBox.shrink();

    final wetness = sensor.soilWetnessPercent();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Environment Status',
            subtitle: 'Current conditions overview',
            icon: FontAwesomeIcons.chartBar,
          ),
          const SizedBox(height: 16),
          _EnvRow(
            label: 'Temperature',
            value: sensor.temperature,
            unit: '°C',
            min: 0,
            max: 50,
            idealMin: 18,
            idealMax: 30,
            color: const Color(0xFFfb7185),
          ),
          const SizedBox(height: 12),
          _EnvRow(
            label: 'Humidity',
            value: sensor.humidity,
            unit: '%',
            min: 0,
            max: 100,
            idealMin: 40,
            idealMax: 80,
            color: AppTheme.accent3,
          ),
          const SizedBox(height: 12),
          _EnvRow(
            label: 'Soil Wetness',
            value: wetness,
            unit: '%',
            min: 0,
            max: 100,
            idealMin: 30,
            idealMax: 75,
            color: AppTheme.accent2,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 200.ms);
  }
}

class _EnvRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final double min, max, idealMin, idealMax;
  final Color color;

  const _EnvRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.min,
    required this.max,
    required this.idealMin,
    required this.idealMax,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final inRange = value >= idealMin && value <= idealMax;
    final pct = ((value - min) / (max - min)).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.textSecondary,
                ),
              ),
            ),
            Text(
              '${value.toStringAsFixed(1)}$unit',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: inRange ? color : AppTheme.warning,
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(
              label: inRange ? 'Ideal' : 'Off-range',
              color: inRange ? AppTheme.accent2 : AppTheme.warning,
            ),
          ],
        ),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppTheme.glassBorder.withOpacity(0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: inRange ? color : AppTheme.warning,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: (inRange ? color : AppTheme.warning).withOpacity(
                        0.4,
                      ),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          'Ideal: ${idealMin.toStringAsFixed(0)}–${idealMax.toStringAsFixed(0)}$unit',
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
        ),
      ],
    );
  }
}

// ─── Tips card ────────────────────────────────────────────────────────────────
class _InsightTipsCard extends StatelessWidget {
  const _InsightTipsCard();

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final sensor = state.sensor;
    if (sensor == null) return const SizedBox.shrink();

    final tips = <String>[];
    final wetness = sensor.soilWetnessPercent();

    if (wetness < 30) {
      tips.add('Soil is dry — schedule irrigation soon to avoid crop stress.');
    } else if (wetness > 80) {
      tips.add(
        'Soil is over-saturated — ensure adequate drainage is in place.',
      );
    } else {
      tips.add(
        'Soil moisture is in optimal range. Continue current irrigation schedule.',
      );
    }

    if (sensor.temperature > 35) {
      tips.add(
        'High temperature detected — consider shading or misting crops.',
      );
    } else if (sensor.temperature < 10) {
      tips.add('Low temperature — protect frost-sensitive crops overnight.');
    }

    if (sensor.humidity < 30) {
      tips.add('Low humidity — increase irrigation frequency or use mulching.');
    } else if (sensor.humidity > 85) {
      tips.add(
        'High humidity — watch for fungal diseases. Improve air circulation.',
      );
    }

    if (sensor.lightLevel < 500) {
      tips.add('Low light today — photosynthesis rates may be reduced.');
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Actionable Tips',
            subtitle: 'Based on current sensor readings',
            icon: FontAwesomeIcons.lightbulb,
          ),
          const SizedBox(height: 14),
          ...tips.asMap().entries.map(
                (e) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accent1.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.accent1.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: AppTheme.accent1.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '${e.key + 1}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.accent1,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          e.value,
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
              ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms, delay: 300.ms);
  }
}

// ─── No data placeholder ──────────────────────────────────────────────────────
class _NoDataPlaceholder extends StatelessWidget {
  final String message;
  const _NoDataPlaceholder({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const FaIcon(
            FontAwesomeIcons.rotate,
            size: 13,
            color: AppTheme.textMuted,
          ),
          const SizedBox(width: 10),
          Text(
            message,
            style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
