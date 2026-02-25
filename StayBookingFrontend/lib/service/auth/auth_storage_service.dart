import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:stay_booking_frontend/model/auth_session.dart';

class AuthStorageService {
  AuthStorageService({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _authSessionKey = 'auth_session_v1';

  final FlutterSecureStorage _secureStorage;

  Future<void> write(AuthSession session) async {
    await _secureStorage.write(
      key: _authSessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  Future<AuthSession?> read() async {
    final raw = await _secureStorage.read(key: _authSessionKey);
    if ((raw ?? '').trim().isEmpty) return null;

    try {
      final decoded = jsonDecode(raw!);
      if (decoded is Map<String, dynamic>) {
        return AuthSession.fromJson(decoded);
      }
      if (decoded is Map) {
        return AuthSession.fromJson(Map<String, dynamic>.from(decoded));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> clear() async {
    await _secureStorage.delete(key: _authSessionKey);
  }
}
