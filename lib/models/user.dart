import 'enums.dart';

class AppUser {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String? photoUrl;
  final List<UserRole> roles;
  final bool emailVerified;
  final String? linkedPlayerId;

  const AppUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    this.photoUrl,
    this.roles = const [UserRole.fan],
    this.emailVerified = false,
    this.linkedPlayerId,
  });

  bool hasRole(UserRole r) => roles.contains(r);
  bool get isScorer => hasRole(UserRole.scorer) || hasRole(UserRole.admin);
  bool get isOrganizer =>
      hasRole(UserRole.organizer) || hasRole(UserRole.admin);
}
