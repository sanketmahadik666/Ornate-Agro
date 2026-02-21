part of 'auth_bloc.dart';

enum AuthStatus { initial, loading, authenticated, failure }

final class AuthState extends Equatable {
  const AuthState._({required this.status, this.user, this.errorMessage});

  const AuthState.initial() : this._(status: AuthStatus.initial);
  const AuthState.loading() : this._(status: AuthStatus.loading);
  const AuthState.authenticated(UserEntity u) : this._(status: AuthStatus.authenticated, user: u);
  const AuthState.failure(String msg) : this._(status: AuthStatus.failure, errorMessage: msg);

  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  @override
  List<Object?> get props => [status, user, errorMessage];
}
