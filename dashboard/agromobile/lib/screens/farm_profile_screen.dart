import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

import '../models/crop_recommendation.dart';
import '../models/farm_profile.dart';
import '../services/crop_recommendation_service.dart';
import '../services/firebase_service.dart';
import '../widgets/glass_card.dart';
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
        const SnackBar(content: Text('Profile saved to Firebase')),
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
          SnackBar(content: Text('Recommendation failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(title: const Text('Farm Profile')),
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
          child: StreamBuilder<FarmProfile>(
            stream: FirebaseService.instance.farmProfileStream(),
            builder: (context, snapshot) {
              final profile = snapshot.data ?? FarmProfile.fromMap(null);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Soil Profile',
                      style:
                          Theme.of(context).textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1.2,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your soil NPK values and pH to get crop recommendations',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white60,
                          ),
                    ),
                    const SizedBox(height: 20),

                    // NPK + pH input form
                    GlassCard(
                      child: SoilProfileForm(
                        profile: profile,
                        onSave: _onSave,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Get Recommendations button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading
                            ? null
                            : () => _getRecommendations(
                                  _lastSavedProfile ?? profile,
                                ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFC2),
                          foregroundColor: const Color(0xFF003328),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          disabledBackgroundColor:
                              const Color(0xFF00FFC2).withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF003328),
                                ),
                              )
                            : const Icon(Icons.eco),
                        label: Text(
                          _isLoading
                              ? 'Analyzing...'
                              : 'Get Crop Recommendations',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Recommendation results
                    if (_recommendations != null || _isLoading) ...[
                      Text(
                        'Recommendations',
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.2,
                                ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    if (_isLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FFC2),
                          ),
                        ),
                      ),

                    if (_recommendations != null)
                      AnimationLimiter(
                        child: Column(
                          children: List.generate(
                            _recommendations!.length,
                            (index) => AnimationConfiguration.staggeredList(
                              position: index,
                              duration: const Duration(milliseconds: 375),
                              child: SlideAnimation(
                                verticalOffset: 50.0,
                                child: FadeInAnimation(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 12),
                                    child: _RecommendationCard(
                                      recommendation: _recommendations![index],
                                      rank: index + 1,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 24),

                    // API Enhancement toggle
                    GlassCard(
                      child: SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        activeColor: const Color(0xFF00FFC2),
                        title: const Text(
                          'API Enhancement',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: const Text(
                          'Use cloud ML model for enhanced recommendations',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        value: CropRecommendationService
                            .instance.useApiEnhancement,
                        onChanged: (val) {
                          setState(() {
                            CropRecommendationService
                                .instance.useApiEnhancement = val;
                          });
                        },
                      ),
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

class _RecommendationCard extends StatelessWidget {
  final CropRecommendation recommendation;
  final int rank;

  const _RecommendationCard({
    required this.recommendation,
    required this.rank,
  });

  @override
  Widget build(BuildContext context) {
    final Color accentColor;
    switch (recommendation.confidence) {
      case 'High':
        accentColor = const Color(0xFF00FFC2);
        break;
      case 'Medium':
        accentColor = const Color(0xFF00E5FF);
        break;
      default:
        accentColor = const Color(0xFFFFA726);
    }

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Rank badge
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    '#$rank',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Crop name
              Expanded(
                child: Text(
                  recommendation.cropName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              // Confidence pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withOpacity(0.3)),
                ),
                child: Text(
                  recommendation.confidence,
                  style: TextStyle(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Fit score bar
          Row(
            children: [
              const Text(
                'Match: ',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: recommendation.fitScore,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${(recommendation.fitScore * 100).toInt()}%',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Reason
          Text(
            recommendation.reason,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 8),
          // Ideal range chips
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _rangeChip('N', recommendation.idealRange.nMin,
                  recommendation.idealRange.nMax),
              _rangeChip('P', recommendation.idealRange.pMin,
                  recommendation.idealRange.pMax),
              _rangeChip('K', recommendation.idealRange.kMin,
                  recommendation.idealRange.kMax),
              _rangeChip('pH', recommendation.idealRange.phMin,
                  recommendation.idealRange.phMax),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeChip(String label, double min, double max) {
    final minStr =
        label == 'pH' ? min.toStringAsFixed(1) : min.toInt().toString();
    final maxStr =
        label == 'pH' ? max.toStringAsFixed(1) : max.toInt().toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        '$label: $minStr-$maxStr',
        style: const TextStyle(color: Colors.white70, fontSize: 10),
      ),
    );
  }
}
