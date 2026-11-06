import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
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

/// Provides the app's GoRouter.
///
/// It is a Riverpod provider so that in Milestone 2 it can watch the auth
/// state and redirect users based on whether they are logged in and their role.
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    routes: [
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
