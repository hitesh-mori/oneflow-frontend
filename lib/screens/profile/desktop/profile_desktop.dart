import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/animated_fade_in.dart';
import '../../../widgets/custom_button.dart';

class ProfileDesktop extends StatelessWidget {
  const ProfileDesktop({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.theme['backgroundColor'],
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.theme['primaryColor'],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            final userType = user?.userType;
            if (userType != null) {
              RouteHelper.navigateToHome(context, userType);
            }
          },
        ),
      ),
      body: AnimatedFadeIn(
        child: Row(
          children: [
            // Left sidebar with user info
            Container(
              width: 350,
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
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.person,
                              size: 60,
                              color: AppColors.theme['primaryColor'],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            user?.name ?? 'User',
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            user?.email ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getUserTypeLabel(user?.userType ?? ''),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Quick Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.theme['textColor'],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildActionButton(
                            icon: Icons.edit_outlined,
                            label: 'Edit Profile',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            onTap: () {},
                          ),
                          const SizedBox(height: 12),
                          _buildActionButton(
                            icon: Icons.security_outlined,
                            label: 'Security',
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Main content area
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(50),
                child: Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Profile Information',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.theme['textColor'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'View and manage your account details',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppColors.theme['secondaryColor'],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      Icons.email_outlined,
                                      'Email Address',
                                      user?.email ?? '',
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildInfoCard(
                                      Icons.phone_outlined,
                                      'Phone Number',
                                      user?.phone ?? 'Not provided',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInfoCard(
                                      Icons.person_outline,
                                      'User Type',
                                      _getUserTypeLabel(user?.userType ?? ''),
                                    ),
                                  ),
                                  const SizedBox(width: 24),
                                  Expanded(
                                    child: _buildInfoCard(
                                      Icons.calendar_today_outlined,
                                      'Member Since',
                                      _formatDate(user?.createdAt ?? ''),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 40),
                        Row(
                          children: [
                            Expanded(
                              child: CustomButton(
                                title: 'Refresh Profile',
                                onTap: () async {
                                  await authProvider.refreshProfile();
                                },
                                icon: Icons.refresh_rounded,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {},
                                icon: const Icon(Icons.edit_outlined),
                                label: const Text('Edit Profile'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.theme['primaryColor'],
                                  side: BorderSide(
                                    color: AppColors.theme['primaryColor'],
                                    width: 2,
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 20),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.theme['backgroundColor'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.theme['primaryColor'], size: 24),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.theme['secondaryColor'],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.theme['textColor'],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.theme['backgroundColor'],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.theme['primaryColor'], size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.theme['textColor'],
              ),
            ),
            const Spacer(),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.theme['secondaryColor'],
            ),
          ],
        ),
      ),
    );
  }

  String _getUserTypeLabel(String userType) {
    switch (userType) {
      case 'type1':
        return 'Type 1 User';
      case 'type2':
        return 'Type 2 User';
      case 'type3':
        return 'Type 3 User';
      default:
        return 'Unknown';
    }
  }

  String _formatDate(String date) {
    if (date.isEmpty) return 'Unknown';
    try {
      final parsedDate = DateTime.parse(date);
      return '${parsedDate.day}/${parsedDate.month}/${parsedDate.year}';
    } catch (e) {
      return 'Unknown';
    }
  }
}
