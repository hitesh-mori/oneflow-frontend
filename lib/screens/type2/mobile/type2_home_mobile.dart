import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/toast_service.dart';
import '../../../widgets/animated_fade_in.dart';
import '../../../widgets/dashboard_card.dart';

class Type2HomeMobile extends StatelessWidget {
  const Type2HomeMobile({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.theme['backgroundColor'],
      appBar: AppBar(
        title: const Text('Type 2 Dashboard'),
        backgroundColor: AppColors.theme['primaryColor'],
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => context.go(Routes.profile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authProvider.logout();
              AppToast.showSuccess(context, 'Logged out successfully');
              context.go(Routes.login);
            },
          ),
        ],
      ),
      body: AnimatedFadeIn(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.theme['primaryColor'],
                      (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Producer Dashboard',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      user?.name ?? 'User',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white60,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Content Management',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.theme['textColor'],
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.1,
                children: [
                  DashboardCard(
                    title: 'Total Content',
                    value: '0',
                    icon: Icons.article_outlined,
                    color: AppColors.theme['primaryColor'],
                  ),
                  DashboardCard(
                    title: 'Published',
                    value: '0',
                    icon: Icons.publish_outlined,
                    color: Colors.green,
                  ),
                  DashboardCard(
                    title: 'Drafts',
                    value: '0',
                    icon: Icons.edit_note_outlined,
                    color: Colors.orange,
                  ),
                  DashboardCard(
                    title: 'Views',
                    value: '0',
                    icon: Icons.visibility_outlined,
                    color: Colors.blue,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
