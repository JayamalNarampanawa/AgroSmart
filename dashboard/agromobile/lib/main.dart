import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'screens/loading_screen.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/settings_service.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  await AuthService.instance.initialize();
  await SettingsService.instance.initialize();
  await AlertService.instance.initialize();
  await FirebaseService.instance.initialize();
  await NotificationService.instance.initialize();

  runApp(const AgriBot());
}

class AgriBot extends StatelessWidget {
  const AgriBot({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: SettingsService.instance.themeMode,
      builder: (context, mode, _) {
        return MaterialApp(
          title: 'AgroSmart',
          themeMode: mode,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          home: const LoadingScreen(),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

