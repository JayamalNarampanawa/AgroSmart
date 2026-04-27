import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_shadows.dart';
import '../theme/app_spacing.dart';
import '../widgets/navigation/modern_bottom_nav.dart';
import 'analytics_screen.dart';
import 'dashboard_screen.dart';
import 'irrigation_control_screen.dart';
import 'light_detector_screen.dart';
import 'login_screen.dart';
import 'ml_crop_recommendation_screen.dart';
import 'notifications_screen.dart';
import 'npk_recommendation_screen.dart';
import 'scada_screen.dart';
import 'sales_forecast_screen.dart';
import 'security_alarm_screen.dart';
import 'settings_screen.dart';
import 'soil_moisture_screen.dart';
import 'weather_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    ScadaScreen(),
    SoilMoistureScreen(),
    IrrigationControlScreen(),
    LightDetectorScreen(),
    SecurityAlarmScreen(),
    AnalyticsScreen(),
    WeatherScreen(),
    NpkRecommendationScreen(),
    MLCropRecommendationScreen(),
    SalesForecastScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(
        icon: Icons.dashboard_rounded, label: 'Dashboard', color: Colors.blue),
    NavigationItem(
        icon: Icons.monitor_heart_rounded,
        label: 'SCADA',
        color: const Color(0xFF00E5FF)),
    NavigationItem(
        icon: Icons.water_drop, label: 'Soil Moisture', color: Colors.brown),
    NavigationItem(icon: Icons.water, label: 'Irrigation', color: Colors.cyan),
    NavigationItem(
        icon: Icons.wb_sunny, label: 'Light Detector', color: Colors.orange),
    NavigationItem(
        icon: Icons.security, label: 'Security Alarm', color: Colors.red),
    NavigationItem(
        icon: Icons.analytics, label: 'Analytics', color: Colors.green),
    NavigationItem(
        icon: Icons.cloud, label: 'Weather', color: Colors.lightBlue),
    NavigationItem(
        icon: Icons.eco, label: 'Crop Advisor', color: const Color(0xFF66BB6A)),
    NavigationItem(
        icon: Icons.smart_toy,
        label: 'ML Crop Prediction',
        color: const Color(0xFF42A5F5)),
    NavigationItem(
        icon: Icons.query_stats,
        label: 'Sales Forecast',
        color: const Color(0xFFFFD166)),
    NavigationItem(
        icon: Icons.notifications,
        label: 'Notifications',
        color: const Color(0xFF00E5FF)),
    NavigationItem(
        icon: Icons.settings,
        label: 'Settings',
        color: const Color(0xFF00FFC2)),
  ];

  final List<ModernBottomNavItem> _bottomItems = const [
    ModernBottomNavItem(
      index: 0,
      icon: Icons.dashboard_rounded,
      label: 'Home',
    ),
    ModernBottomNavItem(
      index: 6,
      icon: Icons.analytics_rounded,
      label: 'Stats',
    ),
    ModernBottomNavItem(
      index: 11,
      icon: Icons.notifications_rounded,
      label: 'Alerts',
    ),
    ModernBottomNavItem(
      index: 12,
      icon: Icons.settings_rounded,
      label: 'Settings',
    ),
  ];

  void _selectIndex(int index) {
    setState(() => _currentIndex = index);
    Navigator.of(context).maybePop();
  }

  Future<void> _logout() async {
    await AuthService.instance.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      key: _scaffoldKey,
      extendBody: true,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      drawer: _AppDrawer(
        currentIndex: _currentIndex,
        items: _navigationItems,
        onSelect: _selectIndex,
        onLogout: _logout,
      ),
      body: Stack(
        children: [
          Positioned.fill(child: _screens[_currentIndex]),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: ModernBottomNav(
              items: _bottomItems,
              selectedIndex: _currentIndex,
              onSelected: _selectIndex,
              onCenterAction: () => _selectIndex(10),
            ),
          ),
          Positioned(
            left: 8,
            top: MediaQuery.of(context).padding.top + 6,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(100),
                onTap: () => _scaffoldKey.currentState?.openDrawer(),
                child: Ink(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark
                        ? AppColors.cardDark.withValues(alpha: 0.94)
                        : Colors.white.withValues(alpha: 0.94),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color:
                          isDark ? AppColors.darkBorder : AppColors.borderSoft,
                    ),
                    boxShadow: isDark ? [] : AppShadows.card,
                  ),
                  child: Icon(
                    Icons.menu_rounded,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppDrawer extends StatelessWidget {
  final int currentIndex;
  final List<NavigationItem> items;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _AppDrawer({
    required this.currentIndex,
    required this.items,
    required this.onSelect,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final width = min(MediaQuery.of(context).size.width * 0.82, 340.0);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      width: width,
      backgroundColor: isDark ? AppColors.bgDark : AppColors.bgLight,
      child: SafeArea(
        child: Column(
          children: [
            _DrawerHeader(),
            Expanded(
              child: ListView.builder(
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  final isSelected = index == currentIndex;
                  return ListTile(
                    onTap: () => onSelect(index),
                    leading: Icon(
                      item.icon,
                      color: isSelected
                          ? item.color
                          : isDark
                              ? Colors.white60
                              : AppColors.textSecondary,
                    ),
                    title: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        color: isSelected
                            ? (isDark ? Colors.white : AppColors.textPrimary)
                            : (isDark
                                ? Colors.white60
                                : AppColors.textSecondary),
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                    ),
                    tileColor:
                        isSelected ? item.color.withValues(alpha: 0.10) : null,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                  );
                },
              ),
            ),
            Divider(
              color: isDark ? AppColors.darkBorder : AppColors.borderSoft,
              height: 1,
            ),
            ListTile(
              onTap: onLogout,
              leading:
                  const Icon(Icons.logout_rounded, color: AppColors.accentRose),
              title: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  color: AppColors.accentRose,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            ),
          ],
        ),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppColors.violetCyanGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.softGlow(AppColors.primary),
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: AuthService.instance.sessionEmail,
        builder: (context, email, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                ),
                child: const Icon(Icons.eco_rounded, color: Colors.white),
              ),
              const SizedBox(height: 10),
              Text(
                'AgroSmart',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email ?? 'Local session',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12,
                  letterSpacing: 0,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class NavigationItem {
  final IconData icon;
  final String label;
  final Color color;

  NavigationItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
