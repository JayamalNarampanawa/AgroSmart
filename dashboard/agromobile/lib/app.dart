import 'package:flutter/material.dart';

import 'screens/home_shell.dart';
import 'screens/login_screen.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

class AgroSmartApp extends StatelessWidget {
  const AgroSmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AgroSmart Mobile',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          debugShowCheckedModeBanner: false,
          home: ValueListenableBuilder<String?>(
            valueListenable: AuthService.instance.sessionEmail,
            builder: (context, email, _) {
              if (email == null) {
                return const LoginScreen();
              }
              return const HomeShell();
            },
          ),
        );
      },
    );
  }
}
