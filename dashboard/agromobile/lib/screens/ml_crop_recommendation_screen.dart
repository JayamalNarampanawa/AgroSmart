import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/notification_model.dart';
import '../services/ml_prediction_service.dart';
import '../services/notification_service.dart';
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

class MLCropRecommendationScreen extends StatefulWidget {
  const MLCropRecommendationScreen({super.key});

  @override
  State<MLCropRecommendationScreen> createState() =>
      _MLCropRecommendationScreenState();
}

class _MLCropRecommendationScreenState extends State<MLCropRecommendationScreen>
    with SingleTickerProviderStateMixin {
  final _nController = TextEditingController();
  final _pController = TextEditingController();
  final _kController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _rainfallController = TextEditingController();
  final _phController = TextEditingController();

  MLPredictionResponse? _prediction;
  bool _isLoading = false;
  String? _errorMessage;
  bool _showResults = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation =
        Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);

    _temperatureController.text = '25';
    _humidityController.text = '70';
    _rainfallController.text = '800';
    _phController.text = '6.5';
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    _temperatureController.dispose();
    _humidityController.dispose();
    _rainfallController.dispose();
    _phController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _predictCrop() async {
    final n = double.tryParse(_nController.text.trim());
    final p = double.tryParse(_pController.text.trim());
    final k = double.tryParse(_kController.text.trim());
    final temperature = double.tryParse(_temperatureController.text.trim());
    final humidity = double.tryParse(_humidityController.text.trim());
    final rainfall = double.tryParse(_rainfallController.text.trim());
    final ph = double.tryParse(_phController.text.trim());

    if (n == null ||
        p == null ||
        k == null ||
        temperature == null ||
        humidity == null ||
        rainfall == null ||
        ph == null) {
      setState(() {
        _errorMessage = 'Please enter valid values for all fields';
        _prediction = null;
        _showResults = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter valid numeric values'),
          backgroundColor: AppColors.accentRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
      NotificationService.instance.addNotification(
        title: 'Crop Prediction Input Error',
        message:
            'Crop prediction needs valid N, P, K, temperature, humidity, rainfall, and pH values.',
        type: NotificationType.warning,
        priority: NotificationPriority.normal,
        source: 'ML Crop Prediction',
        duplicateWindow: const Duration(seconds: 10),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _prediction = null;
      _showResults = false;
    });
    NotificationService.instance.addNotification(
      title: 'Crop Prediction Started',
      message:
          'Running ML crop prediction with N ${n.toStringAsFixed(0)}, P ${p.toStringAsFixed(0)}, K ${k.toStringAsFixed(0)}.',
      type: NotificationType.info,
      priority: NotificationPriority.low,
      source: 'ML Crop Prediction',
      duplicateWindow: const Duration(seconds: 10),
    );

    try {
      final service = MLPredictionService();
      final result = await service.predictCrop(
        N: n,
        P: p,
        K: k,
        temperature: temperature,
        humidity: humidity,
        rainfall: rainfall,
        ph: ph,
      );

      if (mounted) {
        setState(() {
          _prediction = result;
          _isLoading = false;
          if (result.isSuccessful) {
            _errorMessage = null;
            _showResults = true;
            _animationController.forward(from: 0);
            NotificationService.instance.addNotification(
              title: 'Crop Prediction Ready',
              message:
                  'Recommended crop: ${result.predictedCrop} with ${(result.confidence * 100).toStringAsFixed(0)}% confidence.',
              type: NotificationType.success,
              priority: NotificationPriority.high,
              source: 'ML Crop Prediction',
              showSystemAlert: true,
              duplicateWindow: const Duration(seconds: 10),
            );
          } else {
            _errorMessage = result.errorMessage;
            _showResults = false;
            NotificationService.instance.addNotification(
              title: 'Crop Prediction Failed',
              message:
                  result.errorMessage ?? 'The ML crop API returned an error.',
              type: NotificationType.error,
              priority: NotificationPriority.high,
              source: 'ML Crop Prediction',
              showSystemAlert: true,
              duplicateWindow: const Duration(seconds: 10),
            );
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error: ${e.toString()}';
          _showResults = false;
        });
        NotificationService.instance.addNotification(
          title: 'Crop Prediction Failed',
          message: 'The ML crop prediction request failed: $e',
          type: NotificationType.error,
          priority: NotificationPriority.high,
          source: 'ML Crop Prediction',
          showSystemAlert: true,
          duplicateWindow: const Duration(seconds: 10),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusLabel = _prediction?.isSuccessful == true
        ? 'Ready'
        : _isLoading
            ? 'Running'
            : 'ML API';

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
              greeting: 'ML Crop Prediction',
              subtitle: 'Trained model recommendation from soil and climate',
              avatarText: 'M',
              trailing: StatusBadge(
                label: statusLabel,
                icon: Icons.psychology_rounded,
                tone:
                    _isLoading ? StatusBadgeTone.warning : StatusBadgeTone.info,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _MlHero(),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Prediction Inputs',
              subtitle: 'Nutrients, weather, rainfall, and pH',
            ),
            const SizedBox(height: AppSpacing.md),
            _buildInputCard(),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: ModernActionButton.primary(
                label: _isLoading ? 'Analyzing' : 'Get Recommendation',
                icon: _isLoading
                    ? Icons.hourglass_top_rounded
                    : Icons.auto_awesome_rounded,
                onPressed: _isLoading ? null : _predictCrop,
              ),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: AppSpacing.lg),
              AlertCard(
                icon: Icons.error_outline_rounded,
                title: 'Prediction failed',
                message: _errorMessage!,
                color: AppColors.accentRose,
                tone: StatusBadgeTone.error,
              ),
            ],
            if (_showResults && _prediction != null) ...[
              const SizedBox(height: AppSpacing.xxl),
              FadeTransition(
                opacity: _fadeAnimation,
                child: _buildResultsSection(),
              ),
            ] else ...[
              const SizedBox(height: AppSpacing.lg),
              const AlertCard(
                icon: Icons.cloud_sync_rounded,
                title: 'ML API required',
                message:
                    'Run the local ML API and enter the configured values to receive a model prediction.',
                color: AppColors.primary,
                tone: StatusBadgeTone.info,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInputCard() {
    return SoftWhiteCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Soil and environmental parameters',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              StatusBadge(
                label: '7 fields',
                icon: Icons.tune_rounded,
                tone: StatusBadgeTone.info,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: _PredictionField(
                  controller: _nController,
                  label: 'N',
                  hint: 'Nitrogen',
                  icon: Icons.grass_rounded,
                  color: AppColors.accentGreen,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PredictionField(
                  controller: _pController,
                  label: 'P',
                  hint: 'Phosphorus',
                  icon: Icons.bubble_chart_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _PredictionField(
                  controller: _kController,
                  label: 'K',
                  hint: 'Potassium',
                  icon: Icons.eco_rounded,
                  color: AppColors.accentOrange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _PredictionField(
            controller: _temperatureController,
            label: 'Temperature',
            hint: '20-30 C',
            icon: Icons.thermostat_rounded,
            color: AppColors.accentRose,
          ),
          const SizedBox(height: AppSpacing.md),
          _PredictionField(
            controller: _humidityController,
            label: 'Humidity',
            hint: '0-100%',
            icon: Icons.water_drop_rounded,
            color: AppColors.accentCyan,
          ),
          const SizedBox(height: AppSpacing.md),
          _PredictionField(
            controller: _rainfallController,
            label: 'Rainfall',
            hint: 'Annual/seasonal mm',
            icon: Icons.cloud_queue_rounded,
            color: AppColors.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          _PredictionField(
            controller: _phController,
            label: 'pH Level',
            hint: '0-14',
            icon: Icons.science_rounded,
            color: AppColors.accentGreen,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    final prediction = _prediction!;
    final topCrops = prediction.probabilities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Model Result',
          subtitle: 'Recommended crop and probability ranking',
        ),
        const SizedBox(height: AppSpacing.md),
        _PredictionResultCard(prediction: prediction),
        if (topCrops.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xxl),
          const SectionHeader(
            title: 'Crop Probabilities',
            subtitle: 'Model confidence across returned crop classes',
          ),
          const SizedBox(height: AppSpacing.md),
          ...topCrops.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _ProbabilityCard(
                    cropName: entry.value.key,
                    probability: entry.value.value,
                    index: entry.key,
                  ),
                ),
              ),
        ],
      ],
    );
  }
}

class _MlHero extends StatelessWidget {
  const _MlHero();

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
          colors: AppColors.primaryGradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.primary),
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
            child: const Icon(
              Icons.psychology_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trained crop model',
                  style: theme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Predict the best crop from nutrients and climate data.',
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

class _PredictionField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final Color color;

  const _PredictionField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      ],
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

class _PredictionResultCard extends StatelessWidget {
  final MLPredictionResponse prediction;

  const _PredictionResultCard({required this.prediction});

  @override
  Widget build(BuildContext context) {
    final confidence = prediction.confidence.clamp(0.0, 1.0).toDouble();
    final color = _confidenceColor(confidence);
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      backgroundColor: color.withValues(alpha: 0.08),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
                child: Icon(Icons.eco_rounded, color: color, size: 28),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Recommended Crop', style: theme.bodyMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(prediction.predictedCrop, style: theme.titleLarge),
                  ],
                ),
              ),
              StatusBadge(
                label: '${(confidence * 100).toStringAsFixed(0)}%',
                tone: _confidenceTone(confidence),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: confidence,
              minHeight: 9,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Model confidence ${(confidence * 100).toStringAsFixed(1)}%',
            style: theme.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }

  static Color _confidenceColor(double confidence) {
    if (confidence >= 0.8) return AppColors.accentGreen;
    if (confidence >= 0.6) return AppColors.accentOrange;
    return AppColors.accentRose;
  }

  static StatusBadgeTone _confidenceTone(double confidence) {
    if (confidence >= 0.8) return StatusBadgeTone.success;
    if (confidence >= 0.6) return StatusBadgeTone.warning;
    return StatusBadgeTone.error;
  }
}

class _ProbabilityCard extends StatelessWidget {
  final String cropName;
  final double probability;
  final int index;

  const _ProbabilityCard({
    required this.cropName,
    required this.probability,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final value = probability.clamp(0.0, 1.0).toDouble();
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppRadius.chip),
            ),
            child: Text(
              '${index + 1}',
              style: theme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cropName, style: theme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: value,
                    minHeight: 7,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Text(
            '${(value * 100).toStringAsFixed(1)}%',
            style: theme.titleMedium?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
