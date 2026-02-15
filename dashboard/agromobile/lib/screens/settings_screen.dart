import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import '../services/settings_service.dart';
import '../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF050A14),
              const Color(0xFF0B1221),
              const Color(0xFF050A14),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                'Preferences',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 20),
              GlassCard(
                child: ValueListenableBuilder<ThemeMode>(
                  valueListenable: SettingsService.instance.themeMode,
                  builder: (context, mode, _) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.palette,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Theme',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Wrap(
                          spacing: 12,
                          children: [
                            ChoiceChip(
                              label: const Text('Dark'),
                              selected: mode == ThemeMode.dark,
                              onSelected: (_) => SettingsService.instance
                                  .setThemeMode(ThemeMode.dark),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              labelStyle: TextStyle(
                                color: mode == ThemeMode.dark
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white70,
                                fontWeight: mode == ThemeMode.dark
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('Light'),
                              selected: mode == ThemeMode.light,
                              onSelected: (_) => SettingsService.instance
                                  .setThemeMode(ThemeMode.light),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              labelStyle: TextStyle(
                                color: mode == ThemeMode.light
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white70,
                                fontWeight: mode == ThemeMode.light
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            ChoiceChip(
                              label: const Text('System'),
                              selected: mode == ThemeMode.system,
                              onSelected: (_) => SettingsService.instance
                                  .setThemeMode(ThemeMode.system),
                              selectedColor: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withOpacity(0.3),
                              backgroundColor: Colors.white.withOpacity(0.05),
                              labelStyle: TextStyle(
                                color: mode == ThemeMode.system
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.white70,
                                fontWeight: mode == ThemeMode.system
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Account',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.2,
                    ),
              ),
              const SizedBox(height: 16),
              GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.person,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'User Information',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String?>(
                      valueListenable: AuthService.instance.sessionEmail,
                      builder: (context, email, _) {
                        return Text(
                          'Signed in as ${email ?? 'Unknown'}',
                          style: const TextStyle(color: Colors.white70),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => AuthService.instance.logout(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5252),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        icon: const Icon(Icons.logout),
                        label: const Text('Sign Out'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
