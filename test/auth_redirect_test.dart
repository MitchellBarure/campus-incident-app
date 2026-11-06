import 'package:campus_incident_app/core/router/app_router.dart';
import 'package:campus_incident_app/models/app_user.dart';
import 'package:campus_incident_app/services/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('authRedirect', () {
    test('waits on the splash screen while auth is loading', () {
      final result = authRedirect(
        location: AppRoutes.home,
        isAuthLoading: true,
        isLoggedIn: false,
        role: null,
      );
      expect(result, AppRoutes.splash);
    });

    test('sends logged-out users to login', () {
      final result = authRedirect(
        location: AppRoutes.home,
        isAuthLoading: false,
        isLoggedIn: false,
        role: null,
      );
      expect(result, AppRoutes.login);
    });

    test('lets logged-out users stay on login and sign up', () {
      for (final page in [AppRoutes.login, AppRoutes.signup]) {
        final result = authRedirect(
          location: page,
          isAuthLoading: false,
          isLoggedIn: false,
          role: null,
        );
        expect(result, isNull);
      }
    });

    test('waits on the splash screen until the role is known', () {
      final result = authRedirect(
        location: AppRoutes.signup,
        isAuthLoading: false,
        isLoggedIn: true,
        role: null,
      );
      expect(result, AppRoutes.splash);
    });

    test('sends a logged-in student from login to home', () {
      final result = authRedirect(
        location: AppRoutes.login,
        isAuthLoading: false,
        isLoggedIn: true,
        role: UserRole.student,
      );
      expect(result, AppRoutes.home);
    });

    test('sends a logged-in staff member from splash to the dashboard', () {
      final result = authRedirect(
        location: AppRoutes.splash,
        isAuthLoading: false,
        isLoggedIn: true,
        role: UserRole.staff,
      );
      expect(result, AppRoutes.staffDashboard);
    });

    test('blocks students from the staff dashboard', () {
      final result = authRedirect(
        location: AppRoutes.staffDashboard,
        isAuthLoading: false,
        isLoggedIn: true,
        role: UserRole.student,
      );
      expect(result, AppRoutes.home);
    });

    test('sends staff away from student-only pages', () {
      final result = authRedirect(
        location: AppRoutes.reportIncident,
        isAuthLoading: false,
        isLoggedIn: true,
        role: UserRole.staff,
      );
      expect(result, AppRoutes.staffDashboard);
    });

    test('lets both roles open shared pages', () {
      for (final role in UserRole.values) {
        final result = authRedirect(
          location: '/incident/abc123',
          isAuthLoading: false,
          isLoggedIn: true,
          role: role,
        );
        expect(result, isNull);
      }
    });
  });

  group('friendlyAuthMessage', () {
    test('uses one message for wrong password and unknown email', () {
      const expected = 'Incorrect email or password.';
      expect(friendlyAuthMessage('wrong-password'), expected);
      expect(friendlyAuthMessage('user-not-found'), expected);
      expect(friendlyAuthMessage('invalid-credential'), expected);
    });

    test('explains a duplicate email', () {
      expect(
        friendlyAuthMessage('email-already-in-use'),
        'An account with this email already exists.',
      );
    });

    test('falls back to a generic message for unknown codes', () {
      expect(
        friendlyAuthMessage('some-new-code'),
        'Something went wrong. Please try again.',
      );
    });
  });
}
