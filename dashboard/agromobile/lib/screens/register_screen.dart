import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/alert_card.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/modern_action_button.dart';
import '../widgets/common/status_badge.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_passwordController.text != _confirmController.text) {
      setState(() {
        _error = 'Passwords do not match.';
      });
      return;
    }
    setState(() {
      _error = null;
      _loading = true;
    });
    final error = await AuthService.instance.register(
      email: _emailController.text,
      password: _passwordController.text,
    );
    if (!mounted) return;
    setState(() {
      _error = error;
      _loading = false;
    });
    if (error == null) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 0,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _RegisterHero(),
                const SizedBox(height: AppSpacing.lg),
                SoftWhiteCard(
                  title: 'Create Account',
                  subtitle: 'Local authentication for the mobile app',
                  action: const StatusBadge(
                    label: 'Demo',
                    icon: Icons.lock_rounded,
                    tone: StatusBadgeTone.info,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _PremiumTextField(
                        controller: _emailController,
                        label: 'Email',
                        icon: Icons.alternate_email_rounded,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PremiumTextField(
                        controller: _passwordController,
                        label: 'Password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(
                              () => _obscurePassword = !_obscurePassword,
                            );
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _PremiumTextField(
                        controller: _confirmController,
                        label: 'Confirm password',
                        icon: Icons.verified_user_rounded,
                        obscureText: _obscureConfirm,
                        suffixIcon: IconButton(
                          onPressed: () {
                            setState(() => _obscureConfirm = !_obscureConfirm);
                          },
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                          ),
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: AppSpacing.lg),
                        AlertCard(
                          icon: Icons.info_outline_rounded,
                          title: 'Registration unavailable',
                          message: _error!,
                          color: AppColors.accentOrange,
                          tone: StatusBadgeTone.warning,
                        ),
                      ],
                      const SizedBox(height: AppSpacing.lg),
                      ModernActionButton.primary(
                        label: _loading ? 'Creating Account' : 'Register',
                        icon: _loading
                            ? Icons.hourglass_top_rounded
                            : Icons.person_add_alt_1_rounded,
                        onPressed: _loading ? null : _submit,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      ModernActionButton.secondary(
                        label: 'Back to Login',
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                const AlertCard(
                  icon: Icons.key_rounded,
                  title: 'Use demo credentials',
                  message:
                      'This build signs in with admin@agrosmart.com and the demo password shown on the login page.',
                  color: AppColors.primary,
                  tone: StatusBadgeTone.info,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RegisterHero extends StatelessWidget {
  const _RegisterHero();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Container(
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
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AgroSmart Access',
                  style: theme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Secure mobile dashboard account setup',
                  style: theme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
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

class _PremiumTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? suffixIcon;

  const _PremiumTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
    this.keyboardType,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.primary),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : AppColors.bgSoft.withValues(alpha: 0.75),
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
          borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
        ),
      ),
    );
  }
}
