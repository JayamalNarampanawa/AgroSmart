import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../widgets/gradient_background.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: ValueListenableBuilder<ThemeMode>(
                valueListenable: SettingsService.instance.themeMode,
                builder: (context, mode, _) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        children: [
                          ChoiceChip(
                            label: const Text('Dark'),
                            selected: mode == ThemeMode.dark,
                            onSelected: (_) => SettingsService.instance.setThemeMode(ThemeMode.dark),
                          ),
                          ChoiceChip(
                            label: const Text('Light'),
                            selected: mode == ThemeMode.light,
                            onSelected: (_) => SettingsService.instance.setThemeMode(ThemeMode.light),
                          ),
                          ChoiceChip(
                            label: const Text('System'),
                            selected: mode == ThemeMode.system,
                            onSelected: (_) => SettingsService.instance.setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Account', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String?>(
                    valueListenable: AuthService.instance.sessionEmail,
                    builder: (context, email, _) {
                      return Text('Signed in as ${email ?? 'Unknown'}', style: const TextStyle(color: Colors.white70));
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => AuthService.instance.logout(),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                    child: const Text('Sign out', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

