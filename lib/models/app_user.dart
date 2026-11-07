import 'package:cloud_firestore/cloud_firestore.dart';

/// The two kinds of user in the app.
enum UserRole {
  student,
  staff;

  /// Turns the string stored in Firestore back into a [UserRole].
  /// Anything unknown is treated as a student (the safest, least powerful role).
  static UserRole fromString(String? value) {
    if (value == 'staff') return UserRole.staff;
    return UserRole.student;
  }

  /// Human-friendly label, e.g. for the role badge on the profile screen.
  String get label => this == UserRole.staff ? 'Staff' : 'Student';
}

/// A user's profile, stored in Firestore at users/{uid}.
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

  /// Null for a brief moment right after sign up, until the server
  /// fills in the serverTimestamp().
  final DateTime? createdAt;

  bool get isStaff => role == UserRole.staff;

  /// Builds an [AppUser] from a Firestore document's data.
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

  /// The data written to Firestore. The uid is the document id, so it is
  /// not stored again inside the document. createdAt is set by the
  /// repository with serverTimestamp(), so it is not included here.
  Map<String, dynamic> toMap() {
    return {'name': name, 'email': email, 'role': role.name};
  }
}
