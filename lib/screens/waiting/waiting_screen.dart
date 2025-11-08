import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/routing/route_constants.dart';
import '../../core/routing/route_helper.dart';
import '../../providers/auth_provider.dart';
import '../../services/toast_service.dart';

class WaitingScreen extends StatefulWidget {
  const WaitingScreen({super.key});

  @override
  State<WaitingScreen> createState() => _WaitingScreenState();
}

class _WaitingScreenState extends State<WaitingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkUserRole() async {
    if (_isChecking) return;

    setState(() => _isChecking = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Refresh profile from API
      await authProvider.refreshProfile();

      if (mounted) {
        final user = authProvider.user;
        final userType = user?.userType;

        print('🔍 Waiting Screen - Check Status:');
        print('   User: ${user?.name}');
        print('   Email: ${user?.email}');
        print('   UserType: $userType');

        if (userType != null && userType != 'guest') {
          print('✅ Role assigned: $userType - Redirecting...');
          if (mounted) {
            AppToast.showSuccess(context, 'Role assigned! Redirecting...');
          }
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) {
            final route = RouteHelper.getHomeRouteForUserType(userType);
            print('   Navigating to: $route');
            context.go(route);
          }
        } else {
          print('❌ Still guest user');
          if (mounted) {
            AppToast.showInfo(context, 'No role assigned yet. Please wait.');
          }
        }
      }
    } catch (e) {
      print('❌ Error checking role: $e');
      if (mounted) {
        AppToast.showError(context, 'Failed to check role. Please try again.');
      }
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // Left Panel - Branding (same as login/register)
          Expanded(
            flex: 5,
            child: _buildLeftPanel(),
          ),
          // Right Panel - Waiting Message
          Expanded(
            flex: 5,
            child: _buildRightPanel(),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.theme['primaryColor'],
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Decorative geometric shapes
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          Positioned(
            top: 150,
            left: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: 50,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Main content
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                      child: Image.asset("assets/images/oneflow.png"),
                    ),
                  ),
                  const SizedBox(height: 50),
                  const Text(
                    'ONEFLOW',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: -1,
                      height: 1.1,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Plan. Execute. Bill. All in OneFlow',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withValues(alpha: 0.95),
                      height: 1.7,
                      letterSpacing: 0.3,
                      fontWeight: FontWeight.w300,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel() {
    return Container(
      color: Colors.white,
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 60),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Clock Animation
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: _animationController.value * 2 * 3.14159,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (AppColors.theme['primaryColor'] as Color)
                              .withValues(alpha: 0.1),
                          border: Border.all(
                            color: AppColors.theme['primaryColor'],
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Hour hand
                            Transform.rotate(
                              angle: _animationController.value * 2 * 3.14159,
                              child: Container(
                                width: 4,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.theme['primaryColor'],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            // Minute hand
                            Transform.rotate(
                              angle: _animationController.value * 12 * 3.14159,
                              child: Container(
                                width: 3,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: AppColors.theme['secondaryColor'],
                                  borderRadius: BorderRadius.circular(1.5),
                                ),
                              ),
                            ),
                            // Center dot
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.theme['primaryColor'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 50),
                Text(
                  'Please Wait',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w600,
                    color: AppColors.theme['textColor'],
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                  'While admin gives you a role',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.theme['secondaryColor'],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Your account has been created successfully!\nPlease wait for an administrator to assign you a role.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme['secondaryColor'],
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                // Check Status Button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _isChecking ? null : _checkUserRole,
                    child: Container(
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: _isChecking
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Check Status',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                // Divider
                Row(
                  children: [
                    Expanded(
                      child: Divider(
                        color: AppColors.theme['secondaryColor']
                            .withValues(alpha: 0.3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text(
                        'OR',
                        style: TextStyle(
                          color: AppColors.theme['secondaryColor'],
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(
                        color: AppColors.theme['secondaryColor']
                            .withValues(alpha: 0.3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                // Back to Login Button
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () async {
                      final authProvider = Provider.of<AuthProvider>(context, listen: false);
                      await authProvider.logout();
                      if (context.mounted) {
                        context.go(Routes.login);
                      }
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.theme['primaryColor'],
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(
                        child: Text(
                          'Back to Login',
                          style: TextStyle(
                            color: AppColors.theme['primaryColor'],
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
