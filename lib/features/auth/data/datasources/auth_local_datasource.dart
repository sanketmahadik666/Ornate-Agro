import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../../domain/entities/user_entity.dart';

/// Local data source for authentication (secure storage)
class AuthLocalDataSource {
  AuthLocalDataSource(this._secureStorage);

  final FlutterSecureStorage _secureStorage;
  static const String _userKey = 'current_user';
  static const String _sessionTokenKey = 'session_token';
  static const String _sessionExpiryKey = 'session_expiry';

  /// Save user session
  Future<void> saveUser(UserEntity user, {String? sessionToken, DateTime? expiry}) async {
    await _secureStorage.write(
      key: _userKey,
      value: jsonEncode({
        'id': user.id,
        'username': user.username,
        'role': user.role.name,
      }),
    );
    if (sessionToken != null) {
      await _secureStorage.write(key: _sessionTokenKey, value: sessionToken);
    }
    if (expiry != null) {
      await _secureStorage.write(key: _sessionExpiryKey, value: expiry.toIso8601String());
    }
  }

  /// Get saved user
  Future<UserEntity?> getUser() async {
    final userJson = await _secureStorage.read(key: _userKey);
    if (userJson == null) return null;

    try {
      final data = jsonDecode(userJson) as Map<String, dynamic>;
      return UserEntity(
        id: data['id'] as String,
        username: data['username'] as String,
        role: UserRole.values.firstWhere((r) => r.name == data['role']),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    final expiryStr = await _secureStorage.read(key: _sessionExpiryKey);
    if (expiryStr == null) return false;

    try {
      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// Clear all auth data
  Future<void> clearAuthData() async {
    await Future.wait([
      _secureStorage.delete(key: _userKey),
      _secureStorage.delete(key: _sessionTokenKey),
      _secureStorage.delete(key: _sessionExpiryKey),
    ]);
  }

  /// Get session token
  Future<String?> getSessionToken() async {
    return _secureStorage.read(key: _sessionTokenKey);
  }
}
