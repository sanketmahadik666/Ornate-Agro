import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

part 'auth_state.dart';
part 'auth_event.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._authRepository) : super(const AuthState.initial()) {
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthSessionExpired>(_onSessionExpired);
    on<AuthCheckSession>(_onCheckSession);
    
    // Check session on initialization
    add(const AuthCheckSession());
  }

  final AuthRepository _authRepository;

  void _onLoginRequested(AuthLoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthState.loading());
    
    try {
      final user = await _authRepository.login(event.username, event.password);
      emit(AuthState.authenticated(user));
    } on InvalidCredentialsException {
      emit(const AuthState.failure('Invalid username or password'));
    } on AuthException catch (e) {
      emit(AuthState.failure(e.message));
    } catch (e) {
      emit(AuthState.failure('An unexpected error occurred: ${e.toString()}'));
    }
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) async {
    await _authRepository.logout();
    emit(const AuthState.initial());
  }

  void _onSessionExpired(AuthSessionExpired event, Emitter<AuthState> emit) async {
    await _authRepository.clearSession();
    emit(const AuthState.failure('Session has expired. Please log in again.'));
  }

  void _onCheckSession(AuthCheckSession event, Emitter<AuthState> emit) async {
    final user = await _authRepository.getCurrentUser();
    if (user != null) {
      emit(AuthState.authenticated(user));
    }
  }
}
