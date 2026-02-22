import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:percent_indicator/percent_indicator.dart';
import '../services/app_state.dart';
import '../models/crop_database.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SoilAnalysisScreen extends StatefulWidget {
  const SoilAnalysisScreen({super.key});

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  // ── Form values ───────────────────────────────────────────────────────────
  double _n = 50;
  double _p = 50;
  double _k = 50;
  double _ph = 6.5;
  double _temperature = 27;
  double _humidity = 65;
  double _rainfall = 120;

  // ── Category filter ───────────────────────────────────────────────────────
  String? _selectedCategory; // null = all

  // ── Results ───────────────────────────────────────────────────────────────
  List<MapEntry<CropInfo, double>>? _results;

  // ── Selected crop for detail ──────────────────────────────────────────────
  CropInfo? _selectedCrop;

  // ── Use live data ─────────────────────────────────────────────────────────
  bool _useLiveData = false;

  void _analyze(AppState state) {
    if (_useLiveData && state.sensor != null) {
      _temperature = state.sensor!.temperature;
      _humidity = state.sensor!.humidity;
    }

    final results = state.scoreCrops(
      temperature: _temperature,
      humidity: _humidity,
      n: _n,
      p: _p,
      k: _k,
      ph: _ph,
      rainfall: _rainfall,
      categoryFilter: _selectedCategory,
    );

    setState(() {
      _results = results;
      _selectedCrop = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.bgGradient),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: Color(0xFF060d1a),
                border: Border(
                  bottom: BorderSide(color: AppTheme.glassBorder, width: 1),
                ),
              ),
              child: const Row(
                children: [
                  FaIcon(FontAwesomeIcons.leaf,
                      size: 16, color: AppTheme.accent2),
                  SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Soil Advisor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.heading,
                        ),
                      ),
                      Text(
                        'Find the best crops for your soil',
                        style: TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedCrop != null
                  ? _CropDetailView(
                      crop: _selectedCrop!,
                      score: _results!
                          .firstWhere((e) => e.key.id == _selectedCrop!.id)
                          .value,
                      onBack: () => setState(() => _selectedCrop = null),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SoilInputCard(
                            n: _n, p: _p, k: _k, ph: _ph,
                            temperature: _temperature,
                            humidity: _humidity,
                            rainfall: _rainfall,
                            useLiveData: _useLiveData,
                            hasSensor: state.sensor != null,
                            onChanged: (n, p, k, ph, temp, hum, rain, live) {
                              setState(() {
                                _n = n; _p = p; _k = k; _ph = ph;
                                _temperature = temp;
                                _humidity = hum;
                                _rainfall = rain;
                                _useLiveData = live;
                              });
                            },
                          ),
                          const SizedBox(height: 12),
                          _CategoryFilter(
                            selected: _selectedCategory,
                            onChanged: (cat) =>
                                setState(() => _selectedCategory = cat),
                          ),
                          const SizedBox(height: 12),
                          GradientButton(
                            label: 'Analyze Soil & Find Best Crops',
                            icon: FontAwesomeIcons.magnifyingGlass,
                            onPressed: () => _analyze(state),
                            colors: const [
                              AppTheme.accent2,
                              AppTheme.accent1,
                            ],
                          ),
                          const SizedBox(height: 20),
                          if (_results != null) ...[
                            _ResultsHeader(
                                count: _results!.length,
                                category: _selectedCategory),
                            const SizedBox(height: 12),
                            ..._results!.take(20).map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CropResultCard(
                                  crop: e.key,
                                  score: e.value,
                                  rank: _results!.indexOf(e) + 1,
                                  onTap: () =>
                                      setState(() => _selectedCrop = e.key),
                                ),
                              ),
                            ),
                          ] else
                            _EmptyState(),
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

// ─── Soil Input Card ──────────────────────────────────────────────────────────
class _SoilInputCard extends StatelessWidget {
  final double n, p, k, ph, temperature, humidity, rainfall;
  final bool useLiveData, hasSensor;
  final void Function(double n, double p, double k, double ph, double temperature,
      double humidity, double rainfall, bool useLive) onChanged;

  const _SoilInputCard({
    required this.n,
    required this.p,
    required this.k,
    required this.ph,
    required this.temperature,
    required this.humidity,
    required this.rainfall,
    required this.useLiveData,
    required this.hasSensor,
    required this.onChanged,
  });

  void _emit(
    double? n_, double? p_, double? k_, double? ph_,
    double? temp_, double? hum_, double? rain_, bool? live_,
  ) {
    onChanged(
      n_ ?? n, p_ ?? p, k_ ?? k, ph_ ?? ph,
      temp_ ?? temperature, hum_ ?? humidity, rain_ ?? rainfall,
      live_ ?? useLiveData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Soil & Environment Parameters',
            subtitle: 'Adjust values to match your field',
            icon: FontAwesomeIcons.vial,
          ),
          const SizedBox(height: 16),

          // Live data toggle
          if (hasSensor)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              margin: const EdgeInsets.only(bottom: 14),
              decoration: BoxDecoration(
                color: AppTheme.accent1.withOpacity(0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppTheme.accent1.withOpacity(0.2), width: 1),
              ),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.wifi,
                      size: 12, color: AppTheme.accent1),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Use live sensor data for temperature & humidity',
                      style: TextStyle(
                          fontSize: 12, color: AppTheme.textSecondary),
                    ),
                  ),
                  Switch(
                    value: useLiveData,
                    onChanged: (v) => _emit(null, null, null, null, null, null, null, v),
                    activeThumbColor: AppTheme.accent1,
                  ),
                ],
              ),
            ),

          // NPK sliders
          _SliderInput(
            label: 'Nitrogen (N)',
            value: n,
            min: 0,
            max: 150,
            color: AppTheme.accent2,
            unit: 'ppm',
            onChanged: (v) => _emit(v, null, null, null, null, null, null, null),
          ),
          _SliderInput(
            label: 'Phosphorus (P)',
            value: p,
            min: 0,
            max: 150,
            color: AppTheme.accent3,
            unit: 'ppm',
            onChanged: (v) => _emit(null, v, null, null, null, null, null, null),
          ),
          _SliderInput(
            label: 'Potassium (K)',
            value: k,
            min: 0,
            max: 200,
            color: const Color(0xFFfbbf24),
            unit: 'ppm',
            onChanged: (v) => _emit(null, null, v, null, null, null, null, null),
          ),
          _SliderInput(
            label: 'pH Level',
            value: ph,
            min: 3,
            max: 9,
            divisions: 60,
            color: const Color(0xFFa78bfa),
            unit: '',
            onChanged: (v) => _emit(null, null, null, v, null, null, null, null),
          ),

          // Weather inputs (disabled if using live)
          _SliderInput(
            label: 'Temperature',
            value: temperature,
            min: 0,
            max: 50,
            color: const Color(0xFFfb7185),
            unit: '°C',
            enabled: !useLiveData,
            onChanged: (v) => _emit(null, null, null, null, v, null, null, null),
          ),
          _SliderInput(
            label: 'Humidity',
            value: humidity,
            min: 0,
            max: 100,
            color: AppTheme.accent3,
            unit: '%',
            enabled: !useLiveData,
            onChanged: (v) => _emit(null, null, null, null, null, v, null, null),
          ),
          _SliderInput(
            label: 'Rainfall',
            value: rainfall,
            min: 0,
            max: 400,
            color: AppTheme.accent1,
            unit: 'mm',
            onChanged: (v) => _emit(null, null, null, null, null, null, v, null),
          ),
        ],
      ),
    );
  }
}

class _SliderInput extends StatelessWidget {
  final String label;
  final double value;
  final double min, max;
  final int? divisions;
  final Color color;
  final String unit;
  final bool enabled;
  final ValueChanged<double> onChanged;

  const _SliderInput({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    this.divisions,
    required this.color,
    required this.unit,
    this.enabled = true,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: enabled ? AppTheme.textSecondary : AppTheme.textMuted,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(enabled ? 0.12 : 0.05),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  unit.isEmpty
                      ? value.toStringAsFixed(1)
                      : '${value.toStringAsFixed(unit == '%' || unit == '°C' ? 0 : 1)} $unit',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: enabled ? color : AppTheme.textMuted,
                  ),
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: enabled ? color : AppTheme.textMuted,
              inactiveTrackColor:
                  (enabled ? color : AppTheme.textMuted).withOpacity(0.15),
              thumbColor: enabled ? color : AppTheme.textMuted,
              overlayColor: color.withOpacity(0.1),
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 7),
              trackHeight: 3,
            ),
            child: Slider(
              value: value.clamp(min, max),
              min: min,
              max: max,
              divisions: divisions ?? (max - min).toInt(),
              onChanged: enabled ? onChanged : null,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Category filter chips ────────────────────────────────────────────────────
class _CategoryFilter extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  const _CategoryFilter({required this.selected, required this.onChanged});

  static const _cats = <String, String>{
    'all': 'All Crops',
    'vegetable': '🥦 Vegetables',
    'fruit': '🍎 Fruits',
    'grain': '🌾 Grains',
    'legume': '🫘 Legumes',
    'spice': '🌶️ Spices',
  };

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: _cats.entries.map((e) {
          final isSelected =
              (e.key == 'all' && selected == null) ||
              e.key == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onChanged(e.key == 'all' ? null : e.key),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accent1.withOpacity(0.15)
                      : AppTheme.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accent1
                        : AppTheme.glassBorder,
                    width: 1,
                  ),
                ),
                child: Text(
                  e.value,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: isSelected
                        ? AppTheme.accent1
                        : AppTheme.textMuted,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── Results header ───────────────────────────────────────────────────────────
class _ResultsHeader extends StatelessWidget {
  final int count;
  final String? category;

  const _ResultsHeader({required this.count, required this.category});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const FaIcon(FontAwesomeIcons.award,
            size: 14, color: AppTheme.accent2),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Top Matches (${count > 20 ? 20 : count} crops)',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.heading,
            ),
          ),
        ),
        if (category != null)
          StatusBadge(label: category!, color: AppTheme.accent1),
      ],
    );
  }
}

// ─── Crop result card ─────────────────────────────────────────────────────────
class _CropResultCard extends StatelessWidget {
  final CropInfo crop;
  final double score;
  final int rank;
  final VoidCallback onTap;

  const _CropResultCard({
    required this.crop,
    required this.score,
    required this.rank,
    required this.onTap,
  });

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFfbbf24);
    if (rank == 2) return const Color(0xFF9ca3af);
    if (rank == 3) return const Color(0xFFcd7c2f);
    return AppTheme.textMuted;
  }

  Color get _scoreColor {
    if (score >= 75) return AppTheme.accent2;
    if (score >= 50) return AppTheme.warning;
    return AppTheme.danger;
  }

  String get _matchLabel {
    if (score >= 75) return 'Excellent';
    if (score >= 55) return 'Good';
    if (score >= 35) return 'Moderate';
    return 'Poor';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppTheme.glassDeco(
          borderColor: rank <= 3
              ? _rankColor.withOpacity(0.3)
              : AppTheme.glassBorder,
        ),
        child: Row(
          children: [
            // Rank
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: _rankColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  '#$rank',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _rankColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),

            // Emoji
            Text(crop.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 10),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.heading,
                    ),
                  ),
                  Row(
                    children: [
                      StatusBadge(
                        label: _formatCategory(crop.category),
                        color: _categoryColor(crop.category),
                      ),
                      const SizedBox(width: 6),
                      StatusBadge(
                        label: _matchLabel,
                        color: _scoreColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Score circle
            Column(
              children: [
                CircularPercentIndicator(
                  radius: 26,
                  lineWidth: 4,
                  percent: (score / 100).clamp(0, 1),
                  progressColor: _scoreColor,
                  backgroundColor:
                      _scoreColor.withOpacity(0.12),
                  center: Text(
                    score.toStringAsFixed(0),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _scoreColor,
                    ),
                  ),
                  animation: true,
                  animationDuration: 600,
                ),
                const SizedBox(height: 2),
                const FaIcon(FontAwesomeIcons.chevronRight,
                    size: 10, color: AppTheme.textMuted),
              ],
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
    );
  }

  String _formatCategory(String cat) {
    return cat.replaceFirst(cat[0], cat[0].toUpperCase());
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'vegetable':
        return AppTheme.accent2;
      case 'fruit':
        return const Color(0xFFfb7185);
      case 'grain':
        return const Color(0xFFfbbf24);
      case 'legume':
        return AppTheme.accent1;
      case 'spice':
        return const Color(0xFFa78bfa);
      default:
        return AppTheme.textMuted;
    }
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppTheme.accent2.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: AppTheme.accent2.withOpacity(0.25), width: 1),
              ),
              child: const Center(
                child: FaIcon(FontAwesomeIcons.seedling,
                    size: 32, color: AppTheme.accent2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter Soil Parameters',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.heading,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Adjust the sliders above to match your soil\nanalysis results, then tap Analyze.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textMuted,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Crop Detail View ─────────────────────────────────────────────────────────
class _CropDetailView extends StatelessWidget {
  final CropInfo crop;
  final double score;
  final VoidCallback onBack;

  const _CropDetailView({
    required this.crop,
    required this.score,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    Color scoreColor;
    if (score >= 75) {
      scoreColor = AppTheme.accent2;
    } else if (score >= 50) {
      scoreColor = AppTheme.warning;
    } else {
      scoreColor = AppTheme.danger;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button
          GestureDetector(
            onTap: onBack,
            child: const Row(
              children: [
                FaIcon(FontAwesomeIcons.arrowLeft,
                    size: 13, color: AppTheme.accent1),
                SizedBox(width: 8),
                Text(
                  'Back to Results',
                  style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.accent1,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hero card
          GlassCard(
            child: Row(
              children: [
                Text(crop.emoji, style: const TextStyle(fontSize: 52)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.heading,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusBadge(
                        label: crop.category.replaceFirst(
                            crop.category[0],
                            crop.category[0].toUpperCase()),
                        color: AppTheme.accent1,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        crop.description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms),

          const SizedBox(height: 12),

          // Score card
          GlassCard(
            borderColor: scoreColor.withOpacity(0.3),
            gradientColors: [scoreColor.withOpacity(0.06), AppTheme.cardBg],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    CircularPercentIndicator(
                      radius: 40,
                      lineWidth: 6,
                      percent: (score / 100).clamp(0, 1),
                      progressColor: scoreColor,
                      backgroundColor: scoreColor.withOpacity(0.12),
                      center: Text(
                        '${score.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: scoreColor,
                        ),
                      ),
                      animation: true,
                      animationDuration: 800,
                    ),
                    const SizedBox(height: 6),
                    const Text('Match Score',
                        style: TextStyle(
                            fontSize: 11, color: AppTheme.textMuted)),
                  ],
                ),
                _DetailStat(
                  label: 'Temp Range',
                  value:
                      '${crop.tempMin.toInt()}–${crop.tempMax.toInt()}°C',
                  color: const Color(0xFFfb7185),
                ),
                _DetailStat(
                  label: 'pH Range',
                  value:
                      '${crop.phMin}–${crop.phMax}',
                  color: const Color(0xFFa78bfa),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const SizedBox(height: 12),

          // Ideal conditions
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Ideal Growing Conditions',
                  icon: FontAwesomeIcons.circleCheck,
                ),
                const SizedBox(height: 14),
                _ConditionRow('Temperature',
                    '${crop.tempMin.toInt()} – ${crop.tempMax.toInt()} °C'),
                _ConditionRow('Humidity',
                    '${crop.humidityMin.toInt()} – ${crop.humidityMax.toInt()} %'),
                _ConditionRow('Nitrogen (N)',
                    '${crop.nMin.toInt()} – ${crop.nMax.toInt()} ppm'),
                _ConditionRow('Phosphorus (P)',
                    '${crop.pMin.toInt()} – ${crop.pMax.toInt()} ppm'),
                _ConditionRow('Potassium (K)',
                    '${crop.kMin.toInt()} – ${crop.kMax.toInt()} ppm'),
                _ConditionRow('Soil pH',
                    '${crop.phMin} – ${crop.phMax}'),
                _ConditionRow('Rainfall',
                    '${crop.rainfallMin.toInt()} – ${crop.rainfallMax.toInt()} mm'),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),

          const SizedBox(height: 12),

          // Benefits
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Key Benefits',
                  icon: FontAwesomeIcons.star,
                ),
                const SizedBox(height: 14),
                ...crop.benefits.map(
                  (b) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const FaIcon(FontAwesomeIcons.circleCheck,
                            size: 12, color: AppTheme.accent2),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            b,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

          const SizedBox(height: 12),

          // Farming tips
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(
                  title: 'Farming Tips',
                  icon: FontAwesomeIcons.lightbulb,
                ),
                const SizedBox(height: 14),
                ...crop.tips.asMap().entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${e.key + 1}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
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
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
        ],
      ),
    );
  }
}

class _DetailStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _DetailStat(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _ConditionRow extends StatelessWidget {
  final String label;
  final String value;
  const _ConditionRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: AppTheme.textSecondary),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent1.withOpacity(0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                  color: AppTheme.accent1.withOpacity(0.2), width: 1),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppTheme.accent1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
