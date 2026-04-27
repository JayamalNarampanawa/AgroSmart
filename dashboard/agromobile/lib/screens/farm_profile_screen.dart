import 'package:flutter/material.dart';

import '../models/crop_recommendation.dart';
import '../models/farm_profile.dart';
import '../services/crop_recommendation_service.dart';
import '../services/firebase_service.dart';
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
import '../widgets/soil_profile_form.dart';

class FarmProfileScreen extends StatefulWidget {
  const FarmProfileScreen({super.key});

  @override
  State<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends State<FarmProfileScreen> {
  List<CropRecommendation>? _recommendations;
  bool _isLoading = false;
  FarmProfile? _lastSavedProfile;

  Future<void> _onSave(FarmProfile profile) async {
    await FirebaseService.instance.updateFarmProfile(profile);
    setState(() => _lastSavedProfile = profile);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile saved to Firebase'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    _getRecommendations(profile);
  }

  Future<void> _getRecommendations(FarmProfile profile) async {
    setState(() {
      _isLoading = true;
      _recommendations = null;
    });
    try {
      final results = await CropRecommendationService.instance
          .getRecommendations(profile, topN: 5);
      if (mounted) {
        setState(() {
          _recommendations = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recommendation failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: StreamBuilder<FarmProfile>(
        stream: FirebaseService.instance.farmProfileStream(),
        builder: (context, snapshot) {
          final profile = snapshot.data ?? FarmProfile.fromMap(null);

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
                  greeting: 'Farm Profile',
                  subtitle: 'Soil NPK and pH recommendation profile',
                  avatarText: 'F',
                  trailing: StatusBadge(
                    label: CropRecommendationService.instance.useApiEnhancement
                        ? 'Cloud ML'
                        : 'Local rules',
                    icon: Icons.psychology_rounded,
                    tone: CropRecommendationService.instance.useApiEnhancement
                        ? StatusBadgeTone.success
                        : StatusBadgeTone.info,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _ProfileHero(profile: _lastSavedProfile ?? profile),
                const SizedBox(height: AppSpacing.xxl),
                const SectionHeader(
                  title: 'Soil Profile',
                  subtitle: 'Update the nutrient values used for crop advice',
                ),
                const SizedBox(height: AppSpacing.md),
                SoftWhiteCard(
                  child: SoilProfileForm(
                    profile: profile,
                    onSave: _onSave,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                SoftWhiteCard(
                  title: 'Recommendation Engine',
                  subtitle: CropRecommendationService.instance.useApiEnhancement
                      ? 'Cloud ML enhancement is enabled.'
                      : 'Local crop fit scoring is active.',
                  action: Switch.adaptive(
                    value: CropRecommendationService.instance.useApiEnhancement,
                    activeThumbColor: AppColors.accentGreen,
                    onChanged: (val) {
                      setState(() {
                        CropRecommendationService.instance.useApiEnhancement =
                            val;
                      });
                    },
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    child: ModernActionButton.primary(
                      label: _isLoading
                          ? 'Analyzing Soil'
                          : 'Get Crop Recommendations',
                      icon: _isLoading
                          ? Icons.hourglass_top_rounded
                          : Icons.eco_rounded,
                      onPressed: _isLoading
                          ? null
                          : () => _getRecommendations(
                                _lastSavedProfile ?? profile,
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xxl),
                if (_isLoading)
                  const _RecommendationLoading()
                else if (_recommendations != null) ...[
                  const SectionHeader(
                    title: 'Recommendations',
                    subtitle: 'Best crop matches for the saved profile',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...List.generate(
                    _recommendations!.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _RecommendationCard(
                        recommendation: _recommendations![index],
                        rank: index + 1,
                      ),
                    ),
                  ),
                ] else
                  const AlertCard(
                    icon: Icons.eco_rounded,
                    title: 'Ready for crop matching',
                    message:
                        'Save soil values or run recommendations to compare crops against this profile.',
                    color: AppColors.accentGreen,
                    tone: StatusBadgeTone.success,
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final FarmProfile profile;

  const _ProfileHero({required this.profile});

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
                  Icons.agriculture_rounded,
                  color: Colors.white,
                  size: 31,
                ),
              ),
              const Spacer(),
              StatusBadge(
                label: profile.phIsDefault ? 'Default pH' : 'Updated',
                icon: Icons.science_rounded,
                tone: profile.phIsDefault
                    ? StatusBadgeTone.info
                    : StatusBadgeTone.success,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Soil nutrient profile',
            style: theme.displayMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'N ${profile.n.toStringAsFixed(0)} / P ${profile.p.toStringAsFixed(0)} / K ${profile.k.toStringAsFixed(0)} / pH ${profile.ph.toStringAsFixed(1)}',
            style: theme.bodyLarge?.copyWith(
              color: Colors.white.withValues(alpha: 0.86),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              _HeroPill(label: 'N', value: profile.n.toStringAsFixed(0)),
              _HeroPill(label: 'P', value: profile.p.toStringAsFixed(0)),
              _HeroPill(label: 'K', value: profile.k.toStringAsFixed(0)),
              _HeroPill(label: 'pH', value: profile.ph.toStringAsFixed(1)),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final String label;
  final String value;

  const _HeroPill({required this.label, required this.value});

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
      child: Text(
        '$label: $value',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _RecommendationLoading extends StatelessWidget {
  const _RecommendationLoading();

  @override
  Widget build(BuildContext context) {
    return const SoftWhiteCard(
      child: Column(
        children: [
          LinearProgressIndicator(),
          SizedBox(height: AppSpacing.lg),
          Text('Analyzing soil profile...'),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final CropRecommendation recommendation;
  final int rank;

  const _RecommendationCard({
    required this.recommendation,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = switch (recommendation.confidence) {
      'High' => AppColors.accentGreen,
      'Medium' => AppColors.accentCyan,
      _ => AppColors.accentOrange,
    };
    final tone = switch (recommendation.confidence) {
      'High' => StatusBadgeTone.success,
      'Medium' => StatusBadgeTone.info,
      _ => StatusBadgeTone.warning,
    };
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: Text(
                  '#$rank',
                  style: theme.titleMedium?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(recommendation.cropName, style: theme.titleLarge),
              ),
              StatusBadge(label: recommendation.confidence, tone: tone),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: recommendation.fitScore.clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: accentColor.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                '${(recommendation.fitScore * 100).toInt()}%',
                style: theme.titleMedium?.copyWith(
                  color: accentColor,
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

  const _RangeChip({
    required this.label,
    required this.min,
    required this.max,
  });

  @override
  Widget build(BuildContext context) {
    final minStr =
        label == 'pH' ? min.toStringAsFixed(1) : min.toInt().toString();
    final maxStr =
        label == 'pH' ? max.toStringAsFixed(1) : max.toInt().toString();

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
