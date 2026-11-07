import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/app_user.dart';
import '../../models/incident.dart';
import '../../providers/auth_providers.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/splash_screen.dart';
import '../../screens/auth/verify_email_screen.dart';
import '../../screens/shared/browse_reports_screen.dart';
import '../../screens/shared/incident_details_screen.dart';
import '../../screens/shared/profile_screen.dart';
import '../../screens/staff/staff_dashboard_screen.dart';
import '../../screens/student/home_screen.dart';
import '../../screens/student/my_reports_screen.dart';
import '../../screens/student/report_incident_screen.dart';
import '../../screens/student/student_shell.dart';

class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const signup = '/signup';
  static const verifyEmail = '/verify-email';

  // Student tabs (bottom navigation bar).
  static const home = '/home';
  static const browse = '/reports';
  static const myReports = '/my-reports';
  static const profile = '/profile';

  // Full-screen pages pushed on top of the tabs.
  static const reportIncident = '/report';
  static const staffDashboard = '/staff';

  // Staff pages (no bottom bar).
  static const staffProfile = '/staff/profile';

  static String incidentDetails(String id) => '/incident/$id';
  static String editIncident(String id) => '/incident/$id/edit';
}

/// Staff are redirected away from these pages.
const _studentOnlyRoutes = {
  AppRoutes.home,
  AppRoutes.browse,
  AppRoutes.myReports,
  AppRoutes.profile,
  AppRoutes.reportIncident,
};

/// Returns the page to redirect to, or null to stay on [location].
/// [role] is null while the profile is still loading.
String? authRedirect({
  required String location,
  required bool isAuthLoading,
  required bool isLoggedIn,
  required UserRole? role,
  bool isEmailVerified = true,
}) {
  final onAuthPage =
      location == AppRoutes.login || location == AppRoutes.signup;
  final onSplash = location == AppRoutes.splash;

  // 1. Auth state not known yet.
  if (isAuthLoading) {
    return onSplash ? null : AppRoutes.splash;
  }

  // 2. Logged out: only login and sign up.
  if (!isLoggedIn) {
    return onAuthPage ? null : AppRoutes.login;
  }

  // 3. Unverified email: only the verify page.
  final onVerifyPage = location == AppRoutes.verifyEmail;
  if (!isEmailVerified) {
    return onVerifyPage ? null : AppRoutes.verifyEmail;
  }

  // 4. Logged in, role still loading: wait on the splash.
  if (role == null) {
    return onSplash ? null : AppRoutes.splash;
  }

  // 5. Send each role to its own start page.
  final startPage = role == UserRole.staff
      ? AppRoutes.staffDashboard
      : AppRoutes.home;

  if (onAuthPage || onSplash || onVerifyPage) {
    return startPage;
  }
  if (role == UserRole.student &&
      location.startsWith(AppRoutes.staffDashboard)) {
    return startPage;
  }
  if (role == UserRole.staff && _studentOnlyRoutes.contains(location)) {
    return startPage;
  }
  return null;
}

/// The app's router. [refreshNotifier] re-runs [authRedirect] whenever the
/// login state or profile changes.
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
        isEmailVerified: authState.value?.emailVerified ?? false,
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
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) => const VerifyEmailScreen(),
      ),

      // ShellRoute keeps the bottom bar visible while tabs change.
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
        path: '/incident/:id/edit',
        // The details screen passes the loaded incident as `extra`.
        builder: (context, state) =>
            ReportIncidentScreen(existing: state.extra as Incident?),
      ),
      GoRoute(
        path: AppRoutes.staffDashboard,
        builder: (context, state) => const StaffDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.staffProfile,
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
});
