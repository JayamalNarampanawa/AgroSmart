import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'notification_service.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _boxName = 'local_auth';
  static const _sessionKey = 'session_email';

  static const hardcodedEmail = 'admin@agrosmart.com';
  static const hardcodedPassword = 'agro2026';

  late Box _box;
  final ValueNotifier<String?> sessionEmail = ValueNotifier<String?>(null);

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    sessionEmail.value = _box.get(_sessionKey) as String?;
  }

  bool get isLoggedIn => sessionEmail.value != null;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  Future<String?> register({
    required String email,
    required String password,
  }) async {
    return 'Registration is disabled in this demo build. Use the provided login credentials.';
  }

  Future<String?> login({
    required String email,
    required String password,
  }) async {
    final normalized = _normalizeEmail(email);
    if (normalized != hardcodedEmail || password != hardcodedPassword) {
      NotificationService.instance.notifyAuthFailure(normalized);
      return 'Invalid credentials. Use the demo email and password shown on the login page.';
    }

    await _box.put(_sessionKey, hardcodedEmail);
    sessionEmail.value = hardcodedEmail;
    NotificationService.instance.notifyAuthSuccess(hardcodedEmail);
    return null;
  }

  Future<void> logout() async {
    final email = sessionEmail.value;
    await _box.delete(_sessionKey);
    sessionEmail.value = null;
    if (email != null) {
      NotificationService.instance.notifyLogout(email);
    }
  }
}
