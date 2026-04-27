import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/settings_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/cards/soft_white_card.dart';
import '../widgets/common/app_scaffold.dart';
import '../widgets/common/dashboard_header.dart';
import '../widgets/common/section_header.dart';
import '../widgets/common/status_badge.dart';
import 'login_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      bottomInset: 110,
      body: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.sectionLarge,
        ),
        children: const [
          DashboardHeader(
            leading: SizedBox(width: 36, height: 44),
            greeting: 'Settings',
            subtitle: 'System preferences and device controls',
            avatarText: 'S',
          ),
          SizedBox(height: AppSpacing.section),
          _SettingsHero(),
          SizedBox(height: AppSpacing.sectionLarge),
          SectionHeader(
            title: 'System Status',
            subtitle: 'Realtime database and app health',
          ),
          SizedBox(height: AppSpacing.lg),
          _FirebaseStatusCard(),
          SizedBox(height: AppSpacing.sectionLarge),
          SectionHeader(
            title: 'Appearance',
            subtitle: 'Choose how the app should look',
          ),
          SizedBox(height: AppSpacing.lg),
          _ThemeModeCard(),
          SizedBox(height: AppSpacing.sectionLarge),
          SectionHeader(
            title: 'Notifications',
            subtitle: 'Configure alert delivery and priority',
          ),
          SizedBox(height: AppSpacing.lg),
          _NotificationSettingsCard(),
          SizedBox(height: AppSpacing.sectionLarge),
          SectionHeader(
            title: 'Alert Thresholds',
            subtitle: 'Tune sensor limits for notifications',
          ),
          SizedBox(height: AppSpacing.lg),
          _ThresholdsCard(),
          SizedBox(height: AppSpacing.sectionLarge),
          SectionHeader(
            title: 'Account',
            subtitle: 'Current session and sign out',
          ),
          SizedBox(height: AppSpacing.lg),
          _AccountCard(),
          SizedBox(height: AppSpacing.sectionLarge),
          _AppInfoCard(),
        ],
      ),
    );
  }
}

class _SettingsHero extends StatelessWidget {
  const _SettingsHero();

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
          colors: AppColors.violetCyanGradient,
        ),
        borderRadius: AppRadius.cardRadius,
        boxShadow: AppShadows.softGlow(AppColors.primary),
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(color: Colors.white24),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Control Center',
                  style: theme.titleLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Manage alerts, thresholds, theme, and account access.',
                  style: theme.bodyMedium?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FirebaseStatusCard extends StatelessWidget {
  const _FirebaseStatusCard();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DatabaseEvent>(
      stream: FirebaseDatabase.instance.ref('.info/connected').onValue,
      builder: (context, snapshot) {
        final connected = snapshot.data?.snapshot.value == true;
        return SoftWhiteCard(
          child: _SettingsTile(
            icon:
                connected ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
            iconColor: connected ? AppColors.accentGreen : AppColors.accentRose,
            title: 'Firebase Connection',
            subtitle: 'Database: AgroSmart',
            trailing: StatusBadge(
              label: connected ? 'Connected' : 'Offline',
              tone: connected ? StatusBadgeTone.success : StatusBadgeTone.error,
              icon: connected ? Icons.wifi_rounded : Icons.wifi_off_rounded,
            ),
          ),
        );
      },
    );
  }
}

class _ThemeModeCard extends StatelessWidget {
  const _ThemeModeCard();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.instance.themeMode,
      builder: (context, mode, _) {
        return SoftWhiteCard(
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.contrast_rounded,
                iconColor: AppColors.primary,
                title: 'Theme Mode',
                subtitle: _themeSubtitle(mode),
                trailing: StatusBadge(
                  label: _themeLabel(mode),
                  tone: StatusBadgeTone.info,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: _ThemeChoiceButton(
                      label: 'Light',
                      icon: Icons.light_mode_rounded,
                      selected: mode == ThemeMode.light,
                      onTap: () => SettingsService.instance
                          .setThemeMode(ThemeMode.light),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ThemeChoiceButton(
                      label: 'Dark',
                      icon: Icons.dark_mode_rounded,
                      selected: mode == ThemeMode.dark,
                      onTap: () =>
                          SettingsService.instance.setThemeMode(ThemeMode.dark),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _ThemeChoiceButton(
                      label: 'System',
                      icon: Icons.phone_android_rounded,
                      selected: mode == ThemeMode.system,
                      onTap: () => SettingsService.instance
                          .setThemeMode(ThemeMode.system),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  static String _themeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  static String _themeSubtitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Bright premium dashboard surfaces';
      case ThemeMode.dark:
        return 'Low-light dashboard surfaces';
      case ThemeMode.system:
        return 'Follow the device appearance';
    }
  }
}

class _ThemeChoiceButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChoiceButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.button),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.14)
              : isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : AppColors.bgSoft,
          borderRadius: BorderRadius.circular(AppRadius.button),
          border: Border.all(
            color: selected
                ? AppColors.primary.withValues(alpha: 0.35)
                : isDark
                    ? AppColors.darkBorder
                    : AppColors.borderSoft,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? AppColors.primary : null, size: 20),
            const SizedBox(height: AppSpacing.xs),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.labelSmall?.copyWith(
                color: selected ? AppColors.primary : null,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingsCard extends StatelessWidget {
  const _NotificationSettingsCard();

  @override
  Widget build(BuildContext context) {
    return SoftWhiteCard(
      child: Column(
        children: [
          ValueListenableBuilder<int>(
            valueListenable: NotificationService.instance.unreadCount,
            builder: (context, count, _) {
              return _SettingsTile(
                icon: Icons.notifications_active_rounded,
                iconColor: AppColors.accentCyan,
                title: 'Unread Notifications',
                subtitle: 'Messages waiting for review',
                trailing: StatusBadge(
                  label: count.toString(),
                  tone: count > 0
                      ? StatusBadgeTone.warning
                      : StatusBadgeTone.neutral,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<bool>(
            valueListenable: SettingsService.instance.alertsEnabled,
            builder: (context, alertsEnabled, _) {
              return _SwitchSettingTile(
                icon: Icons.campaign_rounded,
                iconColor: AppColors.primary,
                title: 'Enable Alerts',
                subtitle: 'Generate notifications from live sensor changes',
                value: alertsEnabled,
                onChanged: SettingsService.instance.setAlertsEnabled,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          ValueListenableBuilder<bool>(
            valueListenable: SettingsService.instance.highPriorityOnly,
            builder: (context, highPriorityOnly, _) {
              return _SwitchSettingTile(
                icon: Icons.priority_high_rounded,
                iconColor: AppColors.accentOrange,
                title: 'High Priority Only',
                subtitle: 'Only alert on high and critical severity events',
                value: highPriorityOnly,
                onChanged: SettingsService.instance.setHighPriorityOnly,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: NotificationService.instance.markAllAsRead,
              icon: const Icon(Icons.done_all_rounded, size: 18),
              label: const Text('Mark All as Read'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThresholdsCard extends StatelessWidget {
  const _ThresholdsCard();

  @override
  Widget build(BuildContext context) {
    return SoftWhiteCard(
      child: Column(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: SettingsService.instance.soilMoistureDryThreshold,
            builder: (context, value, _) {
              return _SliderSetting(
                icon: Icons.grass_rounded,
                iconColor: AppColors.accentOrange,
                title: 'Soil Moisture Dry Alert',
                subtitle: 'Higher raw value means drier soil',
                value: value,
                min: 1000,
                max: 4095,
                divisions: 61,
                displayValue: value.toStringAsFixed(0),
                onChanged: SettingsService.instance.setSoilMoistureDryThreshold,
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Divider(height: 1),
          const SizedBox(height: AppSpacing.lg),
          ValueListenableBuilder<double>(
            valueListenable: SettingsService.instance.highTempThreshold,
            builder: (context, value, _) {
              return _SliderSetting(
                icon: Icons.device_thermostat_rounded,
                iconColor: AppColors.accentRose,
                title: 'Temperature High Alert',
                subtitle: 'Alert when temperature exceeds this value',
                value: value,
                min: 20,
                max: 50,
                divisions: 60,
                displayValue: '${value.toStringAsFixed(1)} C',
                onChanged: SettingsService.instance.setHighTempThreshold,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard();

  @override
  Widget build(BuildContext context) {
    return SoftWhiteCard(
      child: Column(
        children: [
          ValueListenableBuilder<String?>(
            valueListenable: AuthService.instance.sessionEmail,
            builder: (context, email, _) {
              return _SettingsTile(
                icon: Icons.person_rounded,
                iconColor: AppColors.primary,
                title: 'Signed In',
                subtitle: email ?? 'Unknown session',
                trailing: const StatusBadge(
                  label: 'Active',
                  tone: StatusBadgeTone.success,
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                await AuthService.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (_) => false,
                );
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign Out'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.accentRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.button),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppInfoCard extends StatelessWidget {
  const _AppInfoCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return SoftWhiteCard(
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: AppColors.growthGradient),
              borderRadius: BorderRadius.circular(AppRadius.button),
            ),
            child: const Icon(Icons.eco_rounded, color: Colors.white, size: 30),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('AgroSmart', style: theme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text('Version 1.0.0', style: theme.bodyMedium),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Smart Agriculture Monitoring System',
            textAlign: TextAlign.center,
            style: theme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.button),
          ),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: theme.bodyLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.bodyMedium,
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: AppSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

class _SwitchSettingTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchSettingTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsTile(
      icon: icon,
      iconColor: iconColor,
      title: title,
      subtitle: subtitle,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppColors.primary,
      ),
    );
  }
}

class _SliderSetting extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String displayValue;
  final ValueChanged<double> onChanged;

  const _SliderSetting({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.displayValue,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _SettingsTile(
          icon: icon,
          iconColor: iconColor,
          title: title,
          subtitle: subtitle,
          trailing: StatusBadge(
            label: displayValue,
            tone: StatusBadgeTone.warning,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: iconColor,
            inactiveTrackColor: iconColor.withValues(alpha: 0.18),
            thumbColor: iconColor,
            overlayColor: iconColor.withValues(alpha: 0.14),
            trackHeight: 6,
          ),
          child: Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
