import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/auth_service.dart';
import 'analytics_screen.dart';
import 'camera_feed_screen.dart';
import 'dashboard_screen.dart';
import 'irrigation_control_screen.dart';
import 'light_detector_screen.dart';
import 'login_screen.dart';
import 'notifications_screen.dart';
import 'security_alarm_screen.dart';
import 'settings_screen.dart';
import 'soil_moisture_screen.dart';
import 'water_level_screen.dart';
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
    SoilMoistureScreen(),
    IrrigationControlScreen(),
    WaterLevelScreen(),
    LightDetectorScreen(),
    CameraFeedScreen(),
    SecurityAlarmScreen(),
    AnalyticsScreen(),
    WeatherScreen(),
    NotificationsScreen(),
    SettingsScreen(),
  ];

  final List<NavigationItem> _navigationItems = [
    NavigationItem(icon: Icons.dashboard_rounded, label: 'Dashboard', color: Colors.blue),
    NavigationItem(icon: Icons.water_drop, label: 'Soil Moisture', color: Colors.brown),
    NavigationItem(icon: Icons.water, label: 'Irrigation', color: Colors.cyan),
    NavigationItem(icon: Icons.local_drink, label: 'Water Level', color: Colors.blue),
    NavigationItem(icon: Icons.wb_sunny, label: 'Light Detector', color: Colors.orange),
    NavigationItem(icon: Icons.camera_alt, label: 'Camera Feed', color: Colors.purple),
    NavigationItem(icon: Icons.security, label: 'Security Alarm', color: Colors.red),
    NavigationItem(icon: Icons.analytics, label: 'Analytics', color: Colors.green),
    NavigationItem(icon: Icons.cloud, label: 'Weather', color: Colors.lightBlue),
    NavigationItem(icon: Icons.notifications, label: 'Notifications', color: const Color(0xFF00E5FF)),
    NavigationItem(icon: Icons.settings, label: 'Settings', color: const Color(0xFF00FFC2)),
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
    return Scaffold(
      key: _scaffoldKey,
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
                    color: const Color(0xFF0B1221).withOpacity(0.78),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white10),
                  ),
                  child: const Icon(Icons.menu, color: Color(0xFF00FFC2), size: 20),
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

    return Drawer(
      width: width,
      backgroundColor: const Color(0xFF060D1A),
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
                      color: isSelected ? item.color : Colors.white70,
                    ),
                    title: Text(
                      item.label,
                      style: GoogleFonts.inter(
                        color: isSelected ? Colors.white : Colors.white70,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    tileColor: isSelected ? item.color.withOpacity(0.16) : null,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  );
                },
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            ListTile(
              onTap: onLogout,
              leading: const Icon(Icons.logout, color: Color(0xFFFF5252)),
              title: Text(
                'Sign Out',
                style: GoogleFonts.inter(
                  color: const Color(0xFFFF5252),
                  fontWeight: FontWeight.w600,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
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
          colors: [Color(0x3300FFC2), Color(0x2200E5FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: ValueListenableBuilder<String?>(
        valueListenable: AuthService.instance.sessionEmail,
        builder: (context, email, _) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.eco, color: Color(0xFF00FFC2), size: 36),
              const SizedBox(height: 10),
              Text(
                'AgroSmart',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                email ?? 'Local session',
                style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
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
