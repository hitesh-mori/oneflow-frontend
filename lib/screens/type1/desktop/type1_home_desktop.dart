import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/toast_service.dart';
import '../../../widgets/animated_fade_in.dart';
import '../../../widgets/dashboard_card.dart';

class Type1HomeDesktop extends StatelessWidget {
  const Type1HomeDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.theme['backgroundColor'],
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 280,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(2, 0),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.theme['primaryColor'],
                        (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.person,
                          size: 30,
                          color: AppColors.theme['primaryColor'],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildMenuItem(
                  icon: Icons.dashboard_outlined,
                  title: 'Dashboard',
                  isActive: true,
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Items',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.task_alt_outlined,
                  title: 'Tasks',
                  onTap: () {},
                ),
                _buildMenuItem(
                  icon: Icons.person_outline,
                  title: 'Profile',
                  onTap: () => context.go(Routes.profile),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: InkWell(
                    onTap: () async {
                      await authProvider.logout();
                      AppToast.showSuccess(context, 'Logged out successfully');
                      context.go(Routes.login);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Main Content
          Expanded(
            child: AnimatedFadeIn(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Type 1 Dashboard',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.theme['textColor'],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Type 1 User',
                            style: TextStyle(
                              color: AppColors.theme['primaryColor'],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.wb_sunny_outlined,
                            size: 60,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Welcome Back!',
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Here\'s what\'s happening with your projects today.',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.white.withValues(alpha: 0.9),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Text(
                      'Dashboard Overview',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['textColor'],
                      ),
                    ),
                    const SizedBox(height: 24),
                    GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 4,
                      mainAxisSpacing: 24,
                      crossAxisSpacing: 24,
                      childAspectRatio: 1.2,
                      children: [
                        DashboardCard(
                          title: 'Total Items',
                          value: '0',
                          icon: Icons.inventory_2_outlined,
                          color: AppColors.theme['primaryColor'],
                        ),
                        DashboardCard(
                          title: 'Active Tasks',
                          value: '0',
                          icon: Icons.task_alt_outlined,
                          color: Colors.green,
                        ),
                        DashboardCard(
                          title: 'Pending',
                          value: '0',
                          icon: Icons.pending_actions_outlined,
                          color: Colors.orange,
                        ),
                        DashboardCard(
                          title: 'Completed',
                          value: '0',
                          icon: Icons.check_circle_outline,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    bool isActive = false,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: isActive
                ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: isActive
                    ? AppColors.theme['primaryColor']
                    : AppColors.theme['secondaryColor'],
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? AppColors.theme['primaryColor']
                      : AppColors.theme['textColor'],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
