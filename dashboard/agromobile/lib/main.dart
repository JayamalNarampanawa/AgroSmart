import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/firebase_service.dart';
import 'services/settings_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.instance.initialize();
  await SettingsService.instance.initialize();
  await AlertService.instance.initialize();

  try {
    await Firebase.initializeApp();
    await FirebaseService.instance.initialize();
    runApp(const AgroSmartApp());
  } catch (e) {
    runApp(_FirebaseErrorApp(error: e.toString()));
  }
}

class _FirebaseErrorApp extends StatelessWidget {
  final String error;

  const _FirebaseErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF050A14),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Firebase init failed. Add google-services.json and try again.\n\n$error',
              style: const TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
