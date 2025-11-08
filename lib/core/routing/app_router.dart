import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/type1/type1_home_screen.dart';
import '../../screens/type2/type2_home_screen.dart';
import '../../screens/type3/type3_home_screen.dart';
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
            title: 'Login - Flutter App',
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
            title: 'Sign Up - Flutter App',
            child: SignupScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.type1Home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Type 1 Home - Flutter App',
            child: Type1HomeScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.type2Home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Type 2 Home - Flutter App',
            child: Type2HomeScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.type3Home,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Type 3 Home - Flutter App',
            child: Type3HomeScreen(),
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) => child,
        ),
      ),
      GoRoute(
        path: Routes.profile,
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const PageTitleWrapper(
            title: 'Profile - Flutter App',
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
