import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/crop_recommendation.dart';
import '../services/crop_recommendation_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/modern_action_button.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';

class NpkRecommendationScreen extends StatefulWidget {
  const NpkRecommendationScreen({super.key});

  @override
  State<NpkRecommendationScreen> createState() =>
      _NpkRecommendationScreenState();
}

class _NpkRecommendationScreenState extends State<NpkRecommendationScreen> {
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _phController = TextEditingController(text: '6.5');

  List<CropRecommendation>? _results;
  bool _hasAnalyzed = false;

  static const _targetCrops = ['Chickpea', 'Mung Beans', 'Kidney Beans'];

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _phController.dispose();
    super.dispose();
  }

  void _analyze() {
    final n = double.tryParse(_nController.text.trim());
    final p = double.tryParse(_pController.text.trim());
    final k = double.tryParse(_kController.text.trim());
    final ph = double.tryParse(_phController.text.trim()) ?? 6.5;

    if (n == null || p == null || k == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid N, P, K values'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final results = CropRecommendationService.instance.scoreForCrops(
      n: n,
      p: p,
      k: k,
      ph: ph,
      cropNames: _targetCrops,
    );

    setState(() {
      _results = results;
      _hasAnalyzed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: SingleChildScrollView(
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
              greeting: 'Crop Advisor',
              subtitle: 'NPK crop fit scoring for selected legumes',
              avatarText: 'C',
              trailing: StatusBadge(
                label: _hasAnalyzed ? 'Analyzed' : 'Ready',
                icon: Icons.eco_rounded,
                tone: _hasAnalyzed
                    ? StatusBadgeTone.success
                    : StatusBadgeTone.info,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _AdvisorHero(),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Soil Nutrients',
              subtitle: 'Enter soil values and compare the target crops',
            ),
            const SizedBox(height: AppSpacing.md),
            SoftWhiteCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NPK and pH values',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      StatusBadge(
                        label: '3 crops',
                        icon: Icons.filter_3_rounded,
                        tone: StatusBadgeTone.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: _NpkField(
                          controller: _nController,
                          label: 'N',
                          hint: 'Nitrogen',
                          icon: Icons.grass_rounded,
                          color: AppColors.accentGreen,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NpkField(
                          controller: _pController,
                          label: 'P',
                          hint: 'Phosphorus',
                          icon: Icons.bubble_chart_rounded,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _NpkField(
                          controller: _kController,
                          label: 'K',
                          hint: 'Potassium',
                          icon: Icons.eco_rounded,
                          color: AppColors.accentOrange,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _NpkField(
                          controller: _phController,
                          label: 'pH',
                          hint: '6.5',
                          icon: Icons.science_rounded,
                          color: AppColors.accentCyan,
                          isDecimal: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ModernActionButton.primary(
                label: 'Find Best Crop',
                icon: Icons.auto_awesome_rounded,
                onPressed: _analyze,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_hasAnalyzed && _results != null) ...[
              const SectionHeader(
                title: 'Results',
                subtitle: 'Ranked crop matches for this soil profile',
              ),
              const SizedBox(height: AppSpacing.md),
              ..._results!.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _CropResultCard(
                        recommendation: entry.value,
                        rank: entry.key + 1,
                        isBest: entry.key == 0,
                      ),
                    ),
                  ),
            ] else ...[
              const SectionHeader(
                title: 'Crop Guide',
                subtitle: 'Default ideal ranges used by the advisor',
              ),
              const SizedBox(height: AppSpacing.md),
              const _CropGuideCard(
                name: 'Chickpea',
                range: 'N 20-40 / P 40-60 / K 20-40 / pH 6.0-8.0',
                description:
                    'Drought-tolerant legume that fixes nitrogen and prefers well-drained sandy loam.',
                icon: Icons.grass_rounded,
                color: AppColors.accentOrange,
              ),
              const SizedBox(height: AppSpacing.md),
              const _CropGuideCard(
                name: 'Mung Beans',
                range: 'N 15-25 / P 40-60 / K 20-40 / pH 6.2-7.2',
                description:
                    'Short-season legume with low nitrogen demand for warm, humid conditions.',
                icon: Icons.spa_rounded,
                color: AppColors.accentGreen,
              ),
              const SizedBox(height: AppSpacing.md),
              const _CropGuideCard(
                name: 'Kidney Beans',
                range: 'N 40-60 / P 50-70 / K 30-50 / pH 6.0-7.0',
                description:
                    'Higher nutrient-demand crop that needs fertile, moist soil and good drainage.',
                icon: Icons.local_florist_rounded,
                color: AppColors.accentRose,
              ),
              const SizedBox(height: AppSpacing.lg),
              const AlertCard(
                icon: Icons.info_outline_rounded,
                title: 'Advisor scope',
                message:
                    'This advisor compares Chickpea, Mung Beans, and Kidney Beans using local crop fit scoring.',
                color: AppColors.primary,
                tone: StatusBadgeTone.info,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AdvisorHero extends StatelessWidget {
  const _AdvisorHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppColors.growthGradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.accentGreen),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 32),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Legume crop advisor',
                  style: theme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Score crop fit with soil nutrients and pH.',
                  style: theme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.84),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NpkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;
  final bool isDecimal;

  const _NpkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
      inputFormatters: isDecimal
          ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
          : [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: color, size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.bgSoft.withValues(alpha: 0.72),
        border: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.buttonRadius,
          borderSide: BorderSide(color: color, width: 1.4),
        ),
      ),
    );
  }
}

class _CropGuideCard extends StatelessWidget {
  final String name;
  final String range;
  final String description;
  final IconData icon;
  final Color color;

  const _CropGuideCard({
    required this.name,
    required this.range,
    required this.description,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.titleMedium),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  range,
                  style: theme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(description, style: theme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CropResultCard extends StatelessWidget {
  final CropRecommendation recommendation;
  final int rank;
  final bool isBest;

  const _CropResultCard({
    required this.recommendation,
    required this.rank,
    required this.isBest,
  });

  Color get _accentColor {
    switch (recommendation.cropName) {
      case 'Chickpea':
        return AppColors.accentOrange;
      case 'Mung Beans':
        return AppColors.accentGreen;
      case 'Kidney Beans':
        return AppColors.accentRose;
      default:
        return AppColors.accentCyan;
    }
  }

  IconData get _cropIcon {
    switch (recommendation.cropName) {
      case 'Chickpea':
        return Icons.grass_rounded;
      case 'Mung Beans':
        return Icons.spa_rounded;
      case 'Kidney Beans':
        return Icons.local_florist_rounded;
      default:
        return Icons.eco_rounded;
    }
  }

  StatusBadgeTone get _tone {
    switch (recommendation.confidence) {
      case 'High':
        return StatusBadgeTone.success;
      case 'Medium':
        return StatusBadgeTone.info;
      default:
        return StatusBadgeTone.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (recommendation.fitScore * 100).toInt();
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: isBest ? _accentColor.withValues(alpha: 0.08) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Icon(_cropIcon, color: _accentColor, size: 24),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(recommendation.cropName, style: theme.titleLarge),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      isBest ? 'Best match' : 'Rank #$rank',
                      style: theme.labelSmall?.copyWith(color: _accentColor),
                    ),
                  ],
                ),
              ),
              StatusBadge(label: recommendation.confidence, tone: _tone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: recommendation.fitScore.clamp(0.0, 1.0).toDouble(),
                    backgroundColor: _accentColor.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '$pct%',
                style: theme.titleMedium?.copyWith(
                  color: _accentColor,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(recommendation.reason, style: theme.bodyMedium),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _RangeChip(
                label: 'N',
                min: recommendation.idealRange.nMin,
                max: recommendation.idealRange.nMax,
              ),
              _RangeChip(
                label: 'P',
                min: recommendation.idealRange.pMin,
                max: recommendation.idealRange.pMax,
              ),
              _RangeChip(
                label: 'K',
                min: recommendation.idealRange.kMin,
                max: recommendation.idealRange.kMax,
              ),
              _RangeChip(
                label: 'pH',
                min: recommendation.idealRange.phMin,
                max: recommendation.idealRange.phMax,
                isDecimal: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final double min;
  final double max;
  final bool isDecimal;

  const _RangeChip({
    required this.label,
    required this.min,
    required this.max,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    final minStr = isDecimal ? min.toStringAsFixed(1) : min.toInt().toString();
    final maxStr = isDecimal ? max.toStringAsFixed(1) : max.toInt().toString();

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: AppRadius.chipRadius,
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.14)),
      ),
      child: Text(
        '$label: $minStr-$maxStr',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}
