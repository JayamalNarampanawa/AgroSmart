import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'analytics_screen.dart';
import 'insights_screen.dart';
import 'soil_analysis_screen.dart';
import 'settings_screen.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key});

  static const List<_NavItem> _navItems = [
    _NavItem(icon: FontAwesomeIcons.house, label: 'Dashboard'),
    _NavItem(icon: FontAwesomeIcons.chartLine, label: 'Analytics'),
    _NavItem(icon: FontAwesomeIcons.lightbulb, label: 'Insights'),
    _NavItem(icon: FontAwesomeIcons.leaf, label: 'Soil'),
    _NavItem(icon: FontAwesomeIcons.gear, label: 'Settings'),
  ];

  static const List<Widget> _screens = [
    HomeScreen(),
    AnalyticsScreen(),
    InsightsScreen(),
    SoilAnalysisScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    return Scaffold(
      backgroundColor: AppTheme.bgDark,
      body: IndexedStack(index: state.navIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: state.navIndex,
        onTap: state.setNavIndex,
        items: _navItems,
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem({required this.icon, required this.label});
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NavItem> items;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF060d1a),
        border: const Border(
          top: BorderSide(color: AppTheme.glassBorder, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accent1.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(items.length, (i) {
              final selected = i == currentIndex;
              return Expanded(
                child: InkWell(
                  onTap: () => onTap(i),
                  borderRadius: BorderRadius.circular(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: selected
                            ? BoxDecoration(
                                color: AppTheme.accent1.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(20),
                              )
                            : null,
                        child: FaIcon(
                          items[i].icon,
                          size: 16,
                          color: selected
                              ? AppTheme.accent1
                              : AppTheme.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: selected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: selected
                              ? AppTheme.accent1
                              : AppTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
