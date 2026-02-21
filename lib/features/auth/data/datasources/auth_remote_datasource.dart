import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

/// Remote data source for authentication (API calls)
/// TODO: Replace with actual API implementation
class AuthRemoteDataSource {
  /// Mock user database for demo
  /// In production, this would call a real API
  static final Map<String, Map<String, dynamic>> _mockUsers = {
    'authority': {
      'password': 'authority123',
      'role': 'authority',
      'id': 'user-auth-001',
    },
    'staff': {
      'password': 'staff123',
      'role': 'staff',
      'id': 'user-staff-001',
    },
    'admin': {
      'password': 'admin123',
      'role': 'authority',
      'id': 'user-admin-001',
    },
  };

  /// Authenticate user with username and password
  /// Returns user data if successful
  Future<Map<String, dynamic>> login(String username, String password) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));

    final userData = _mockUsers[username.toLowerCase()];
    if (userData == null || userData['password'] != password) {
      throw InvalidCredentialsException();
    }

    return {
      'id': userData['id'],
      'username': username,
      'role': userData['role'],
      'sessionToken': 'mock_token_${DateTime.now().millisecondsSinceEpoch}',
      'expiresAt': DateTime.now().add(const Duration(minutes: 30)),
    };
  }

  /// Validate session token
  Future<bool> validateSession(String token) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock validation - in production, call API
    return token.startsWith('mock_token_');
  }
}
