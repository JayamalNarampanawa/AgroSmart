import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/crop_recommendation.dart';
import '../services/crop_recommendation_service.dart';
import '../widgets/glass_card.dart';

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
        const SnackBar(content: Text('Please enter valid N, P, K values')),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Crop Advisor'),
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Text(
                  'NPK Crop Recommendation',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Enter your soil NPK & pH values to find the best crop among Chickpea, Mung Beans and Kidney Beans',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white60,
                      ),
                ),
                const SizedBox(height: 24),

                // NPK Input Card
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Soil Nutrient Values',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: _NpkField(
                              controller: _nController,
                              label: 'N',
                              hint: 'Nitrogen',
                              color: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NpkField(
                              controller: _pController,
                              label: 'P',
                              hint: 'Phosphorus',
                              color: const Color(0xFFFFA726),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _NpkField(
                              controller: _kController,
                              label: 'K',
                              hint: 'Potassium',
                              color: const Color(0xFF42A5F5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _NpkField(
                        controller: _phController,
                        label: 'pH',
                        hint: 'Soil pH (default 6.5)',
                        color: const Color(0xFFAB47BC),
                        isDecimal: true,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Analyze Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _analyze,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFC2),
                      foregroundColor: const Color(0xFF003328),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: const Icon(Icons.eco),
                    label: const Text(
                      'Find Best Crop',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Results
                if (_hasAnalyzed && _results != null) ...[
                  Text(
                    'Results',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 16),
                  ..._results!.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: _CropResultCard(
                            recommendation: entry.value,
                            rank: entry.key + 1,
                            isBest: entry.key == 0,
                          ),
                        ),
                      ),
                ],

                // Crop Info Guide
                if (!_hasAnalyzed) ...[
                  Text(
                    'Crop Guide',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _buildCropGuide(
                    'Chickpea',
                    'N: 20\u201340  |  P: 40\u201360  |  K: 20\u201340  |  pH: 6.0\u20138.0',
                    'Drought-tolerant legume, fixes nitrogen. Thrives in well-drained sandy loam.',
                    Icons.grass,
                    const Color(0xFFFFC107),
                  ),
                  const SizedBox(height: 12),
                  _buildCropGuide(
                    'Mung Beans',
                    'N: 15\u201325  |  P: 40\u201360  |  K: 20\u201340  |  pH: 6.2\u20137.2',
                    'Short-season legume, low nitrogen demand. Prefers warm, humid conditions.',
                    Icons.spa,
                    const Color(0xFF66BB6A),
                  ),
                  const SizedBox(height: 12),
                  _buildCropGuide(
                    'Kidney Beans',
                    'N: 40\u201360  |  P: 50\u201370  |  K: 30\u201350  |  pH: 6.0\u20137.0',
                    'Higher nutrient demand. Needs fertile, moist soil with good drainage.',
                    Icons.local_florist,
                    const Color(0xFFEF5350),
                  ),
                ],

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCropGuide(
    String name,
    String range,
    String description,
    IconData icon,
    Color color,
  ) {
    return GlassCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  range,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white54,
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

// ------------------------------------------------------------------
// NPK text field
// ------------------------------------------------------------------
class _NpkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final Color color;
  final bool isDecimal;

  const _NpkField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.color,
    this.isDecimal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          inputFormatters: isDecimal
              ? [FilteringTextInputFormatter.allow(RegExp(r'[\d.]'))]
              : [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: Colors.white, fontSize: 16),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 13),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------------
// Crop result card
// ------------------------------------------------------------------
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
        return const Color(0xFFFFC107);
      case 'Mung Beans':
        return const Color(0xFF66BB6A);
      case 'Kidney Beans':
        return const Color(0xFFEF5350);
      default:
        return const Color(0xFF00E5FF);
    }
  }

  IconData get _cropIcon {
    switch (recommendation.cropName) {
      case 'Chickpea':
        return Icons.grass;
      case 'Mung Beans':
        return Icons.spa;
      case 'Kidney Beans':
        return Icons.local_florist;
      default:
        return Icons.eco;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pct = (recommendation.fitScore * 100).toInt();
    final Color confColor;
    switch (recommendation.confidence) {
      case 'High':
        confColor = const Color(0xFF00FFC2);
        break;
      case 'Medium':
        confColor = const Color(0xFF00E5FF);
        break;
      default:
        confColor = const Color(0xFFFFA726);
    }

    return GlassCard(
      startColor: isBest ? const Color(0xFF142A1E) : const Color(0xFF111C2E),
      endColor: isBest ? const Color(0xFF0C1A14) : const Color(0xFF0B1221),
      borderOpacity: isBest ? 0.25 : 0.1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_cropIcon, color: _accentColor, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
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
                        if (isBest)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF00FFC2)
                                  .withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(0xFF00FFC2)
                                    .withValues(alpha: 0.4),
                              ),
                            ),
                            child: const Text(
                              'Best Match',
                              style: TextStyle(
                                color: Color(0xFF00FFC2),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      recommendation.confidence,
                      style: TextStyle(
                        color: confColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Match bar
          Row(
            children: [
              const Text(
                'Match  ',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: recommendation.fitScore,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(_accentColor),
                    minHeight: 7,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$pct%',
                style: TextStyle(
                  color: _accentColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Reason
          Text(
            recommendation.reason,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 10),

          // Ideal range chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _chip('N', recommendation.idealRange.nMin,
                  recommendation.idealRange.nMax),
              _chip('P', recommendation.idealRange.pMin,
                  recommendation.idealRange.pMax),
              _chip('K', recommendation.idealRange.kMin,
                  recommendation.idealRange.kMax),
              _chip('pH', recommendation.idealRange.phMin,
                  recommendation.idealRange.phMax,
                  isDecimal: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, double min, double max, {bool isDecimal = false}) {
    final minStr = isDecimal ? min.toStringAsFixed(1) : min.toInt().toString();
    final maxStr = isDecimal ? max.toStringAsFixed(1) : max.toInt().toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Text(
        '$label: $minStr\u2013$maxStr',
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
    );
  }
}
