import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_helper.dart';
import '../../../providers/auth_provider.dart';
import '../../../widgets/animated_fade_in.dart';
import '../../../widgets/custom_button.dart';

class ProfileTablet extends StatelessWidget {
  const ProfileTablet({super.key});

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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Center(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 700),
              child: Container(
                padding: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 65,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Text(
                      user?.name ?? 'User',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['textColor'],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getUserTypeLabel(user?.userType ?? ''),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.theme['primaryColor'],
                        ),
                      ),
                    ),
                    const SizedBox(height: 36),
                    _buildInfoRow(Icons.email_outlined, 'Email', user?.email ?? ''),
                    const SizedBox(height: 18),
                    _buildInfoRow(Icons.phone_outlined, 'Phone', user?.phone ?? 'Not provided'),
                    const SizedBox(height: 18),
                    _buildInfoRow(Icons.person_outline, 'User Type', _getUserTypeLabel(user?.userType ?? '')),
                    const SizedBox(height: 18),
                    _buildInfoRow(Icons.calendar_today_outlined, 'Member Since', _formatDate(user?.createdAt ?? '')),
                    const SizedBox(height: 36),
                    CustomButton(
                      title: 'Refresh Profile',
                      onTap: () async {
                        await authProvider.refreshProfile();
                      },
                      icon: Icons.refresh_rounded,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.theme['backgroundColor'],
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.theme['primaryColor'], size: 26),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.theme['secondaryColor'],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: AppColors.theme['textColor'],
                  ),
                ),
              ],
            ),
          ),
        ],
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
