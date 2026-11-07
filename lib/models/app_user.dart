import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student,
  staff;

  /// Unknown values become student, the least powerful role.
  static UserRole fromString(String? value) {
    if (value == 'staff') return UserRole.staff;
    return UserRole.student;
  }

  String get label => this == UserRole.staff ? 'Staff' : 'Student';
}

/// A user's profile at users/{uid}.
class AppUser {
  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.createdAt,
  });

  final String uid;
  final String name;
  final String email;
  final UserRole role;

  /// Null right after sign up, until the server timestamp arrives.
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    final createdAt = map['createdAt'];

    return AppUser(
      uid: uid,
      name: map['name'] as String? ?? '',
      email: map['email'] as String? ?? '',
      role: UserRole.fromString(map['role'] as String?),
      createdAt: createdAt is Timestamp ? createdAt.toDate() : null,
    );
  }

  /// Excludes uid (the doc id) and createdAt (set by the repository).
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'role': role.name};
  }
}
