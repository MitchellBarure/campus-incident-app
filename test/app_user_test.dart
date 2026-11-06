import 'package:campus_incident_app/models/app_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppUser', () {
    test('fromMap reads every field', () {
      final created = DateTime(2026, 11, 6, 10, 30);
      final user = AppUser.fromMap('uid-1', {
        'name': 'Mitchell',
        'email': 'mitchell@alustudent.com',
        'role': 'staff',
        'createdAt': Timestamp.fromDate(created),
      });

      expect(user.uid, 'uid-1');
      expect(user.name, 'Mitchell');
      expect(user.email, 'mitchell@alustudent.com');
      expect(user.role, UserRole.staff);
      expect(user.isStaff, isTrue);
      expect(user.createdAt, created);
    });

    test('fromMap treats a missing or unknown role as student', () {
      final noRole = AppUser.fromMap('uid-2', {'name': 'A', 'email': 'a@b.co'});
      final oddRole = AppUser.fromMap('uid-3', {'role': 'admin'});

      expect(noRole.role, UserRole.student);
      expect(oddRole.role, UserRole.student);
    });

    test('fromMap allows a pending (null) createdAt', () {
      final user = AppUser.fromMap('uid-4', {'createdAt': null});
      expect(user.createdAt, isNull);
    });

    test('toMap stores the role as a plain string', () {
      const user = AppUser(
        uid: 'uid-5',
        name: 'Amina',
        email: 'amina@alustudent.com',
        role: UserRole.student,
      );

      expect(user.toMap(), {
        'name': 'Amina',
        'email': 'amina@alustudent.com',
        'role': 'student',
      });
    });
  });
}
