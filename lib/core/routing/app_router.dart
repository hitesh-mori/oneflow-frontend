import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/waiting/waiting_screen.dart';
import '../../screens/dashboards/project_manager/project_manager_dashboard.dart';
import '../../screens/dashboards/team_member/team_member_dashboard.dart';
import '../../screens/dashboards/sales_dep/sales_dep_dashboard.dart';
import '../../screens/dashboards/admin/admin_dashboard.dart';
import '../../screens/profile/profile_screen.dart';
import '../../services/storage_service.dart';
import '../../widgets/page_title_wrapper.dart';
import 'route_constants.dart';
import 'route_helper.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: Routes.login,
    redirect: (BuildContext context, GoRouterState state) async {
      final isLoggedIn = await StorageService.isLoggedIn();
      final isAuthRoute = state.matchedLocation == Routes.login ||
                          state.matchedLocation == Routes.signup;

      if (!isLoggedIn && !isAuthRoute) {
        return Routes.login;
      }

      if (isLoggedIn && isAuthRoute) {
        final userType = await StorageService.getUserType();
        return RouteHelper.getHomeRouteForUserType(userType);
      }

      return null;
    },
    routes: [
      GoRoute(
        path: Routes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Login - OneFlow',
            child: LoginScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.signup,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Sign Up - OneFlow',
            child: SignupScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.waiting,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Waiting for Role - OneFlow',
            child: WaitingScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.projectManagerDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Project Manager Dashboard - OneFlow',
            child: ProjectManagerDashboard(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.teamMemberDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Team Member Dashboard - OneFlow',
            child: TeamMemberDashboard(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.salesDepDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Sales Department Dashboard - OneFlow',
            child: SalesDepDashboard(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.adminDashboard,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Admin Dashboard - OneFlow',
            child: AdminDashboard(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.profile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Profile - OneFlow',
            child: ProfileScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.matchedLocation}'),
      ),
    ),
  );
}
