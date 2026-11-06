import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../providers/auth_providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/shared/browse_reports_screen.dart';
import '../../screens/shared/incident_details_screen.dart';
import '../../screens/shared/profile_screen.dart';
import '../../screens/staff/staff_dashboard_screen.dart';
import '../../screens/student/home_screen.dart';
import '../../screens/student/my_reports_screen.dart';
import '../../screens/student/report_incident_screen.dart';
import '../../screens/student/student_shell.dart';

/// All route paths in one place, so we never mistype a path string.
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';

  // Student tabs (shown inside the bottom navigation bar).
  static const home = '/home';
  static const browse = '/reports';
  static const myReports = '/my-reports';
  static const profile = '/profile';

  // Full-screen pages pushed on top of the tabs.
  static const reportIncident = '/report';
  static const staffDashboard = '/staff';

  static String incidentDetails(String id) => '/incident/$id';
}

/// Pages only students should see. Staff are sent to their dashboard.
const _studentOnlyRoutes = {
  AppRoutes.home,
  AppRoutes.myReports,
  AppRoutes.reportIncident,
};

/// Decides where a user should go, based on login state and role.
///
/// Returns the path to redirect to, or null to stay on [location].
/// [role] is null while the profile is still loading (or not created yet).
/// It is a plain function (no Firebase) so it can be unit tested.
String? authRedirect({
  required String location,
  required bool isAuthLoading,
  required bool isLoggedIn,
  required UserRole? role,
}) {
  final onAuthPage =
      location == AppRoutes.login || location == AppRoutes.signup;
  final onSplash = location == AppRoutes.splash;

  // 1. Firebase hasn't told us yet whether someone is logged in.
  if (isAuthLoading) {
    return onSplash ? null : AppRoutes.splash;
  }

  // 2. Logged out: only the login and sign up pages are allowed.
  if (!isLoggedIn) {
    return onAuthPage ? null : AppRoutes.login;
  }

  // 3. Logged in, but we don't know the role yet: wait on the splash.
  if (role == null) {
    return onSplash ? null : AppRoutes.splash;
  }

  // 4. Logged in with a known role: send each role to its own start page.
  final startPage =
      role == UserRole.staff ? AppRoutes.staffDashboard : AppRoutes.home;

  if (onAuthPage || onSplash) {
    return startPage;
  }
  if (role == UserRole.student && location == AppRoutes.staffDashboard) {
    return startPage;
  }
  if (role == UserRole.staff && _studentOnlyRoutes.contains(location)) {
    return startPage;
  }
  return null;
}

/// Provides the app's GoRouter.
///
/// The router is created once. When the login state or the profile changes,
/// we bump [refreshNotifier], which tells go_router to run [authRedirect]
/// again so the user lands on the right page.
final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ValueNotifier<int>(0);
  ref.onDispose(refreshNotifier.dispose);

  // ref.listen runs the callback every time the provider's value changes.
  ref.listen(authStateProvider, (_, _) => refreshNotifier.value++);
  ref.listen(currentUserProfileProvider, (_, _) => refreshNotifier.value++);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);
      final profile = ref.read(currentUserProfileProvider).value;

      return authRedirect(
        location: state.matchedLocation,
        isAuthLoading: authState.isLoading,
        isLoggedIn: authState.value != null,
        role: profile?.role,
      );
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),

      // ShellRoute keeps the bottom navigation bar visible while the
      // child route (the current tab) changes.
      ShellRoute(
        builder: (context, state, child) => StudentShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.browse,
            builder: (context, state) => const BrowseReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.myReports,
            builder: (context, state) => const MyReportsScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      GoRoute(
        path: AppRoutes.reportIncident,
        builder: (context, state) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/incident/:id',
        builder: (context, state) {
          final incidentId = state.pathParameters['id']!;
          return IncidentDetailsScreen(incidentId: incidentId);
        },
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
    ],
  );
});
