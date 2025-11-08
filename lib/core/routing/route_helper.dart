import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'route_constants.dart';
import '../../models/user_model.dart';

class RouteHelper {
  /// Get the home route path based on user type
  static String getHomeRouteForUserType(String? userType) {
    switch (userType) {
      case UserTypes.projectManager:
        return Routes.projectManagerDashboard;
      case UserTypes.teamMember:
        return Routes.teamMemberDashboard;
      case UserTypes.salesDep:
        return Routes.salesDepDashboard;
      case UserTypes.admin:
        return Routes.adminDashboard;
      case UserTypes.guest:
        return Routes.waiting;
      default:
        return Routes.login;
    }
  }

  /// Navigate to the appropriate home screen based on user type
  static void navigateToHome(BuildContext context, String? userType) {
    context.go(getHomeRouteForUserType(userType));
  }

  /// Check if user is guest and needs to wait
  static bool isGuestUser(String? userType) {
    return userType == UserTypes.guest || userType == null || userType.isEmpty;
  }
}
