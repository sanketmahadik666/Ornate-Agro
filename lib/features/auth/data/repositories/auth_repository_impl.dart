import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

/// Implementation of AuthRepository
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._localDataSource, this._remoteDataSource);

  final AuthLocalDataSource _localDataSource;
  final AuthRemoteDataSource _remoteDataSource;

  @override
  Future<UserEntity> login(String username, String password) async {
    try {
      // Validate input
      if (username.trim().isEmpty || password.isEmpty) {
        throw InvalidCredentialsException();
      }

      // Call remote data source (API)
      final response = await _remoteDataSource.login(username, password);

      // Create user entity
      final user = UserEntity(
        id: response['id'] as String,
        username: response['username'] as String,
        role: UserRole.values.firstWhere(
          (r) => r.name == response['role'] as String,
        ),
      );

      // Save to local storage
      await _localDataSource.saveUser(
        user,
        sessionToken: response['sessionToken'] as String?,
        expiry: response['expiresAt'] as DateTime?,
      );

      return user;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Login failed: ${e.toString()}');
    }
  }

  @override
  Future<void> logout() async {
    await _localDataSource.clearAuthData();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    // Check if session is valid
    final isValid = await _localDataSource.isSessionValid();
    if (!isValid) {
      await _localDataSource.clearAuthData();
      return null;
    }

    return _localDataSource.getUser();
  }

  @override
  Future<bool> isAuthenticated() async {
    final user = await getCurrentUser();
    return user != null;
  }

  @override
  Future<void> clearSession() async {
    await _localDataSource.clearAuthData();
  }
}
