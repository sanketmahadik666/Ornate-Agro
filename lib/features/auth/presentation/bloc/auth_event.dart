part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.username, required this.password});
  final String username;
  final String password;
  
  @override
  List<Object?> get props => [username];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthSessionExpired extends AuthEvent {
  const AuthSessionExpired();
}

final class AuthCheckSession extends AuthEvent {
  const AuthCheckSession();
}
