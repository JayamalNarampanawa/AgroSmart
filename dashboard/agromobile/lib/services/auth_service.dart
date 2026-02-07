import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  static const _boxName = 'local_auth';
  static const _sessionKey = 'session_email';

  late Box _box;
  final ValueNotifier<String?> sessionEmail = ValueNotifier<String?>(null);

  Future<void> initialize() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
    sessionEmail.value = _box.get(_sessionKey) as String?;
  }

  bool get isLoggedIn => sessionEmail.value != null;

  String _normalizeEmail(String email) => email.trim().toLowerCase();

  String _generateSalt() {
    final rand = Random.secure();
    final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
    return base64Url.encode(bytes);
  }

  String _hashPassword(String email, String password, String salt) {
    final bytes = utf8.encode('$email|$password|$salt');
    return sha256.convert(bytes).toString();
  }

  Future<String?> register({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    if (normalized.isEmpty || !normalized.contains('@')) {
      return 'Please enter a valid email address.';
    }
    if (password.length < 6) {
      return 'Password must be at least 6 characters.';
    }
    final userKey = 'user:$normalized';
    if (_box.containsKey(userKey)) {
      return 'User already exists. Please log in.';
    }
    final salt = _generateSalt();
    final hash = _hashPassword(normalized, password, salt);
    await _box.put(userKey, {'hash': hash, 'salt': salt});
    await _box.put(_sessionKey, normalized);
    sessionEmail.value = normalized;
    return null;
  }

  Future<String?> login({required String email, required String password}) async {
    final normalized = _normalizeEmail(email);
    final userKey = 'user:$normalized';
    final stored = _box.get(userKey);
    if (stored is! Map) {
      return 'User not found. Please register.';
    }
    final salt = stored['salt']?.toString() ?? '';
    final hash = stored['hash']?.toString() ?? '';
    if (salt.isEmpty || hash.isEmpty) {
      return 'Stored credentials are invalid.';
    }
    final attempt = _hashPassword(normalized, password, salt);
    if (attempt != hash) {
      return 'Incorrect password.';
    }
    await _box.put(_sessionKey, normalized);
    sessionEmail.value = normalized;
    return null;
  }

  Future<void> logout() async {
    await _box.delete(_sessionKey);
    sessionEmail.value = null;
  }
}
