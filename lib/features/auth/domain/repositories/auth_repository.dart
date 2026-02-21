import '../entities/user_entity.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Login with username and password
  /// Returns UserEntity if successful, throws AuthException on failure
  Future<UserEntity> login(String username, String password);

  /// Logout current user
  Future<void> logout();

  /// Get current authenticated user
  /// Returns null if no user is logged in
  Future<UserEntity?> getCurrentUser();

  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Clear session data
  Future<void> clearSession();
}

/// Authentication exceptions
class AuthException implements Exception {
  AuthException(this.message);
  final String message;
  @override
  String toString() => 'AuthException: $message';
}

class InvalidCredentialsException extends AuthException {
  InvalidCredentialsException() : super('Invalid username or password');
}

class SessionExpiredException extends AuthException {
  SessionExpiredException() : super('Session has expired');
}
