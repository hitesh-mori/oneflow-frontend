import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_constants.dart';

class RouteHelper {
  /// Get the home route path based on user type
  static String getHomeRouteForUserType(String? userType) {
    switch (userType) {
      case 'type1':
        return Routes.type1Home;
      case 'type2':
        return Routes.type2Home;
      case 'type3':
        return Routes.type3Home;
      default:
        return Routes.login;
    }
  }

  /// Navigate to the appropriate home screen based on user type
  static void navigateToHome(BuildContext context, String? userType) {
    context.go(getHomeRouteForUserType(userType));
  }
}
