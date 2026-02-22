import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nCtrl;
  late TextEditingController _pCtrl;
  late TextEditingController _kCtrl;
  late TextEditingController _phCtrl;
  late TextEditingController _wetMinCtrl;
  late TextEditingController _dryMaxCtrl;

  bool _saving = false;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    final profile = context.read<AppState>().farmProfile;
    _nCtrl = TextEditingController(text: profile.n.toStringAsFixed(0));
    _pCtrl = TextEditingController(text: profile.p.toStringAsFixed(0));
    _kCtrl = TextEditingController(text: profile.k.toStringAsFixed(0));
    _phCtrl = TextEditingController(text: profile.ph.toStringAsFixed(1));
    _wetMinCtrl = TextEditingController(
      text: profile.soilMoistureWetMin.toString(),
    );
    _dryMaxCtrl = TextEditingController(
      text: profile.soilMoistureDryMax.toString(),
    );
  }

  @override
  void dispose() {
    _nCtrl.dispose();
    _pCtrl.dispose();
    _kCtrl.dispose();
    _phCtrl.dispose();
    _wetMinCtrl.dispose();
    _dryMaxCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _savedMessage = null;
    });

    final current = context.read<AppState>().farmProfile;
    final updated = current.copyWith(
      n: double.tryParse(_nCtrl.text) ?? current.n,
      p: double.tryParse(_pCtrl.text) ?? current.p,
      k: double.tryParse(_kCtrl.text) ?? current.k,
      ph: double.tryParse(_phCtrl.text) ?? current.ph,
      soilMoistureWetMin:
          int.tryParse(_wetMinCtrl.text) ?? current.soilMoistureWetMin,
      soilMoistureDryMax:
          int.tryParse(_dryMaxCtrl.text) ?? current.soilMoistureDryMax,
    );

    await context.read<AppState>().saveFarmProfile(updated);

    setState(() {
      _saving = false;
      _savedMessage = 'Settings saved to Firebase successfully.';
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _savedMessage = null);
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
                    FontAwesomeIcons.gear,
                    size: 16,
                    color: AppTheme.accent1,
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.heading,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Success message
                      if (_savedMessage != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accent2.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.accent2.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const FaIcon(
                                FontAwesomeIcons.circleCheck,
                                size: 14,
                                color: AppTheme.accent2,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _savedMessage!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.accent2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 300.ms),

                      // NPK / pH card
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Soil NPK & pH Values',
                              subtitle:
                                  'Configure soil nutrient levels for crop recommendations',
                              icon: FontAwesomeIcons.vial,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _NumField(
                                    ctrl: _nCtrl,
                                    label: 'Nitrogen (N)',
                                    hint: '0–150',
                                    color: AppTheme.accent2,
                                    min: 0,
                                    max: 150,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _NumField(
                                    ctrl: _pCtrl,
                                    label: 'Phosphorus (P)',
                                    hint: '0–150',
                                    color: AppTheme.accent3,
                                    min: 0,
                                    max: 150,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: _NumField(
                                    ctrl: _kCtrl,
                                    label: 'Potassium (K)',
                                    hint: '0–200',
                                    color: const Color(0xFFfbbf24),
                                    min: 0,
                                    max: 200,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _NumField(
                                    ctrl: _phCtrl,
                                    label: 'Soil pH',
                                    hint: '3.0–9.0',
                                    color: const Color(0xFFa78bfa),
                                    min: 3,
                                    max: 9,
                                    isDecimal: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms),

                      const SizedBox(height: 14),

                      // Soil moisture calibration
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Soil Moisture Calibration',
                              subtitle:
                                  'Set raw ADC range for wet/dry thresholds',
                              icon: FontAwesomeIcons.droplet,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _NumField(
                                    ctrl: _wetMinCtrl,
                                    label: 'Wet Min (ADC)',
                                    hint: '0–4095',
                                    color: AppTheme.accent2,
                                    min: 0,
                                    max: 4095,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _NumField(
                                    ctrl: _dryMaxCtrl,
                                    label: 'Dry Max (ADC)',
                                    hint: '0–4095',
                                    color: AppTheme.warning,
                                    min: 0,
                                    max: 4095,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppTheme.accent1.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Default: Wet Min = 1200 (sensor in water), '
                                'Dry Max = 4095 (sensor in air). '
                                'Lower values = wetter reading.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.textMuted,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                      const SizedBox(height: 14),

                      // Notification settings
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Alerts & Notifications',
                              subtitle:
                                  'Real-time threshold alerts on your device',
                              icon: FontAwesomeIcons.bell,
                            ),
                            const SizedBox(height: 14),
                            const _AlertThresholdTile(
                              icon: FontAwesomeIcons.droplet,
                              label: 'Soil Dry Alert',
                              description: 'Notify when soil wetness < 25%',
                              color: AppTheme.accent2,
                            ),
                            const _AlertThresholdTile(
                              icon: FontAwesomeIcons.temperatureHigh,
                              label: 'Heat Alert',
                              description: 'Notify when temperature > 35°C',
                              color: AppTheme.danger,
                            ),
                            const _AlertThresholdTile(
                              icon: FontAwesomeIcons.cloudSun,
                              label: 'Low Light Alert',
                              description: 'Notify when light < 500 lux',
                              color: AppTheme.warning,
                            ),
                            const SizedBox(height: 10),
                            GradientButton(
                              label: 'Test Notification',
                              icon: FontAwesomeIcons.bell,
                              onPressed: () =>
                                  NotificationService().showTestNotification(),
                              colors: const [
                                Color(0xFF7c3aed),
                                AppTheme.accent1,
                              ],
                              height: 44,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 200.ms),

                      const SizedBox(height: 14),

                      // Dark mode toggle
                      GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SectionHeader(
                              title: 'Appearance',
                              icon: FontAwesomeIcons.palette,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                const FaIcon(
                                  FontAwesomeIcons.moon,
                                  size: 14,
                                  color: AppTheme.accent3,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Dark Mode',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        'Always-on dark theme for outdoor use',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.textMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: state.darkMode,
                                  onChanged: (v) =>
                                      context.read<AppState>().toggleDarkMode(),
                                  activeThumbColor: AppTheme.accent1,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms),

                      const SizedBox(height: 20),

                      // Save button
                      GradientButton(
                        label: _saving ? 'Saving...' : 'Save to Firebase',
                        icon: FontAwesomeIcons.cloudArrowUp,
                        onPressed: _saving ? null : _save,
                        colors: const [AppTheme.accent1, AppTheme.accent2],
                        height: 52,
                      ),

                      const SizedBox(height: 24),

                      // App info
                      const Center(
                        child: Column(
                          children: [
                            FaIcon(
                              FontAwesomeIcons.seedling,
                              size: 24,
                              color: AppTheme.accent1,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'AgroSmart v1.0.0',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textMuted,
                              ),
                            ),
                            Text(
                              'Smart Farming · Firebase Realtime Database',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppTheme.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
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

class _NumField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final Color color;
  final double min, max;
  final bool isDecimal;

  const _NumField({
    required this.ctrl,
    required this.label,
    required this.hint,
    required this.color,
    required this.min,
    required this.max,
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
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: ctrl,
          keyboardType: TextInputType.numberWithOptions(decimal: isDecimal),
          style: const TextStyle(
            fontSize: 14,
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: hint,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color.withOpacity(0.25), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: color, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.danger, width: 1),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.danger, width: 1.5),
            ),
            filled: true,
            fillColor: color.withOpacity(0.04),
          ),
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Required';
            final n = double.tryParse(v.trim());
            if (n == null) return 'Invalid number';
            if (n < min || n > max) return '$min–$max';
            return null;
          },
        ),
      ],
    );
  }
}

class _AlertThresholdTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;

  const _AlertThresholdTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Center(child: FaIcon(icon, size: 13, color: color)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppTheme.textMuted,
                  ),
                ),
              ],
            ),
          ),
          StatusBadge(label: 'Active', color: color),
        ],
      ),
    );
  }
}
