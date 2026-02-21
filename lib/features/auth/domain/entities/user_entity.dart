import 'package:equatable/equatable.dart';

enum UserRole { authority, staff }

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    required this.role,
  });

  final String id;
  final String username;
  final UserRole role;

  bool get isAuthority => role == UserRole.authority;
  bool get isStaff => role == UserRole.staff;

  @override
  List<Object?> get props => [id, username, role];
}
