import 'package:flutter/material.dart';

import '../models/farm_profile.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'common/modern_action_button.dart';
import 'common/status_badge.dart';

class SoilProfileForm extends StatefulWidget {
  final FarmProfile profile;
  final ValueChanged<FarmProfile> onSave;

  const SoilProfileForm({
    super.key,
    required this.profile,
    required this.onSave,
  });

  @override
  State<SoilProfileForm> createState() => _SoilProfileFormState();
}

class _SoilProfileFormState extends State<SoilProfileForm> {
  late TextEditingController nController;
  late TextEditingController pController;
  late TextEditingController kController;
  late TextEditingController phController;

  @override
  void initState() {
    super.initState();
    nController =
        TextEditingController(text: widget.profile.n.toStringAsFixed(0));
    pController =
        TextEditingController(text: widget.profile.p.toStringAsFixed(0));
    kController =
        TextEditingController(text: widget.profile.k.toStringAsFixed(0));
    phController =
        TextEditingController(text: widget.profile.ph.toStringAsFixed(1));
  }

  @override
  void didUpdateWidget(covariant SoilProfileForm oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile != widget.profile) {
      nController.text = widget.profile.n.toStringAsFixed(0);
      pController.text = widget.profile.p.toStringAsFixed(0);
      kController.text = widget.profile.k.toStringAsFixed(0);
      phController.text = widget.profile.ph.toStringAsFixed(1);
    }
  }

  @override
  void dispose() {
    nController.dispose();
    pController.dispose();
    kController.dispose();
    phController.dispose();
    super.dispose();
  }

  void _save() {
    final n = double.tryParse(nController.text.trim()) ?? widget.profile.n;
    final p = double.tryParse(pController.text.trim()) ?? widget.profile.p;
    final k = double.tryParse(kController.text.trim()) ?? widget.profile.k;
    final ph = double.tryParse(phController.text.trim()) ?? widget.profile.ph;
    final updated = FarmProfile(
      n: n,
      p: p,
      k: k,
      ph: ph,
      phIsDefault: ph == 6.5,
    );
    widget.onSave(updated);
  }

  InputDecoration _fieldDecoration(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color, size: 20),
      filled: true,
      fillColor: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : AppColors.bgSoft.withValues(alpha: 0.7),
      border: OutlineInputBorder(
        borderRadius: AppRadius.buttonRadius,
        borderSide:
            BorderSide(color: AppColors.borderSoft.withValues(alpha: 0.8)),
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('NPK and pH', style: theme.titleMedium)),
            StatusBadge(
              label: widget.profile.phIsDefault ? 'Default pH' : 'Updated pH',
              tone: widget.profile.phIsDefault
                  ? StatusBadgeTone.neutral
                  : StatusBadgeTone.success,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: nController,
                decoration: _fieldDecoration(
                  context,
                  'Nitrogen',
                  Icons.grass_rounded,
                  AppColors.accentGreen,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: pController,
                decoration: _fieldDecoration(
                  context,
                  'Phosphorus',
                  Icons.bubble_chart_rounded,
                  AppColors.primary,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: kController,
                decoration: _fieldDecoration(
                  context,
                  'Potassium',
                  Icons.eco_rounded,
                  AppColors.accentOrange,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: TextField(
                controller: phController,
                decoration: _fieldDecoration(
                  context,
                  'pH',
                  Icons.science_rounded,
                  AppColors.accentCyan,
                ),
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        SizedBox(
          width: double.infinity,
          child: ModernActionButton.primary(
            label: 'Save Soil Profile',
            icon: Icons.save_rounded,
            onPressed: _save,
          ),
        ),
      ],
    );
  }
}
