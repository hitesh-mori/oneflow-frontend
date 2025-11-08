import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/toast_service.dart';
import '../../../services/api_service.dart';
import '../../../services/expense_service.dart';
import '../../../models/user_model.dart';
import '../../../models/expense_model.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> with TickerProviderStateMixin {
  String _selectedMenu = 'users';
  List<UserModel> _users = [];
  List<UserModel> _filteredUsers = [];
  bool _isLoadingUsers = false;
  late AnimationController _pulseAnimationController;
  late Animation<double> _pulseAnimation;

  // Search and Filter
  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'createdAt';
  bool _sortAscending = false;
  String _roleFilter = 'all';

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 8;
  int _totalPages = 1;

  // Update form controllers
  final TextEditingController _hourlyRateController = TextEditingController();
  String? _selectedRole;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _pulseAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.6,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseAnimationController,
      curve: Curves.easeInOut,
    ));

    _searchController.addListener(_filterUsers);
    _fetchUsers();
  }

  @override
  void dispose() {
    _pulseAnimationController.dispose();
    _searchController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await ApiService.get('/api/user', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> usersData = data['data']['users'] ?? [];
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.user?.id;

          setState(() {
            // Filter out current user
            _users = usersData
                .map((user) => UserModel.fromJson(user))
                .where((user) => user.id != currentUserId)
                .toList();
            _filterUsers();
            _isLoadingUsers = false;
          });
        }
      } else {
        setState(() => _isLoadingUsers = false);
        if (mounted) {
          AppToast.showError(context, 'Failed to load users');
        }
      }
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        AppToast.showError(context, 'Error: ${e.toString()}');
      }
    }
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    List<UserModel> filtered = _users.where((user) {
      final matchesSearch = user.name.toLowerCase().contains(query) ||
          user.email.toLowerCase().contains(query) ||
          UserTypes.getLabel(user.userType).toLowerCase().contains(query);

      final matchesRole = _roleFilter == 'all' || user.userType == _roleFilter;

      return matchesSearch && matchesRole;
    }).toList();

    // Sort
    if (_sortBy == 'createdAt') {
      filtered.sort((a, b) {
        final aDate = DateTime.tryParse(a.createdAt ?? '') ?? DateTime(2000);
        final bDate = DateTime.tryParse(b.createdAt ?? '') ?? DateTime(2000);
        return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
    } else if (_sortBy == 'role') {
      filtered.sort((a, b) {
        final comparison = a.userType.compareTo(b.userType);
        return _sortAscending ? comparison : -comparison;
      });
    }

    setState(() {
      _filteredUsers = filtered;
      _totalPages = (_filteredUsers.length / _itemsPerPage).ceil();
      if (_totalPages == 0) _totalPages = 1;
      if (_currentPage > _totalPages) _currentPage = _totalPages;
    });
  }

  List<UserModel> get _paginatedUsers {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;
    return _filteredUsers.sublist(
      startIndex,
      endIndex > _filteredUsers.length ? _filteredUsers.length : endIndex,
    );
  }

  Future<void> _updateUser(UserModel user, BuildContext dialogContext) async {
    setState(() => _isUpdating = true);
    try {
      final Map<String, dynamic> updateData = {};
      if (_selectedRole != null && _selectedRole != user.userType) {
        updateData['userType'] = _selectedRole;
      }
      final hourlyRate = double.tryParse(_hourlyRateController.text);
      if (hourlyRate != null && hourlyRate != user.hourlyRate) {
        updateData['hourlyRate'] = hourlyRate;
      }

      if (updateData.isEmpty) {
        setState(() => _isUpdating = false);
        if (mounted) {
          AppToast.showInfo(context, 'No changes to update');
        }
        return;
      }

      final response = await ApiService.put(
        '/api/user/${user.id}',
        updateData,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          if (mounted) {
            AppToast.showSuccess(context, 'User updated successfully');
            Navigator.of(dialogContext).pop();
          }
          await _fetchUsers();
        }
      } else {
        if (mounted) {
          AppToast.showError(context, 'Failed to update user');
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdating = false);
      }
    }
  }

  void _openUserDialog(UserModel user) {
    setState(() {
      _selectedRole = user.userType;
      _hourlyRateController.text = user.hourlyRate.toString();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return _buildUserDetailsDialog(user);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final admin = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.theme['backgroundColor'],
      body: Row(
        children: [
          _buildSidebar(admin),
          Expanded(
            child: _buildMainContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(UserModel? admin) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white,
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.02),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
            blurRadius: 30,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.theme['primaryColor'],
                  (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/images/oneflow.png',
                        height: 60,
                        width: 60,
                        color: Colors.white,
                      ),
                      Text("ONEFLOW",style: TextStyle(fontWeight: FontWeight.bold,color: AppColors.theme['cardColor'],fontSize: 20),)
                    ],
                  )
                ),
                const SizedBox(height: 28),
                Container(
                  width: 90,
                  height: 90,
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
                  child: Center(
                    child: Text(
                      (admin?.name.isNotEmpty ?? false) ? admin!.name[0].toUpperCase() : 'A',
                      style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['primaryColor'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  admin?.name ?? 'Admin',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  admin?.email ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: const Text(
                    'Administrator',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: Text(
                      'MENU',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['secondaryColor'],
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                  _buildMenuItem(
                    icon: Icons.people_rounded,
                    title: 'Users',
                    isActive: _selectedMenu == 'users',
                    onTap: () => setState(() => _selectedMenu = 'users'),
                  ),
                  _buildMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Expenses',
                    isActive: _selectedMenu == 'expenses',
                    onTap: () => setState(() => _selectedMenu = 'expenses'),
                  ),
                  _buildMenuItem(
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    isActive: _selectedMenu == 'profile',
                    onTap: () => setState(() => _selectedMenu = 'profile'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.logout();
                  if (mounted) {
                    AppToast.showSuccess(context, 'Logged out successfully');
                    context.go(Routes.login);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFEF4444),
                        const Color(0xFFDC2626),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.logout_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'Logout',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
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
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
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
                const SizedBox(width: 14),
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
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedMenu == 'profile') {
      return _buildProfileView();
    } else if (_selectedMenu == 'users') {
      return _buildUsersView();
    } else if (_selectedMenu == 'expenses') {
      return AdminExpensesView();
    }
    return const SizedBox();
  }

  Widget _buildProfileView() {
    final authProvider = Provider.of<AuthProvider>(context);
    final admin = authProvider.user;

    return Container(
      padding: const EdgeInsets.all(48),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        (admin?.name.isNotEmpty ?? false) ? admin!.name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          admin?.name ?? 'Admin',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: AppColors.theme['textColor'],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          admin?.email ?? '',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.theme['secondaryColor'],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    AppColors.theme['primaryColor'],
                                    (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [
                                  BoxShadow(
                                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Text(
                                'Administrator',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(25),
                                border: Border.all(
                                  color: Colors.green.shade200,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: Colors.green,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active',
                                    style: TextStyle(
                                      color: Colors.green.shade700,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 3,
                childAspectRatio: 1.8,
                crossAxisSpacing: 24,
                mainAxisSpacing: 24,
                children: [
                  _buildProfileInfoCard(
                    Icons.email_rounded,
                    'Email Address',
                    admin?.email ?? 'N/A',
                    Colors.blue,
                  ),
                  _buildProfileInfoCard(
                    Icons.phone_rounded,
                    'Phone Number',
                    admin?.phone ?? 'Not provided',
                    Colors.green,
                  ),
                  _buildProfileInfoCard(
                    Icons.attach_money_rounded,
                    'Hourly Rate',
                    '\$${admin?.hourlyRate ?? 0}/hr',
                    Colors.orange,
                  ),
                  _buildProfileInfoCard(
                    Icons.calendar_today_rounded,
                    'Last Login',
                    admin?.lastLogin != null
                        ? _formatDate(admin!.lastLogin!)
                        : 'N/A',
                    Colors.purple,
                  ),
                  _buildProfileInfoCard(
                    Icons.schedule_rounded,
                    'Joined',
                    admin?.createdAt != null
                        ? _formatDate(DateTime.parse(admin!.createdAt!))
                        : 'N/A',
                    Colors.indigo,
                  ),
                  _buildProfileInfoCard(
                    Icons.update_rounded,
                    'Last Updated',
                    admin?.updatedAt != null
                        ? _formatDate(DateTime.parse(admin!.updatedAt!))
                        : 'N/A',
                    Colors.teal,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileInfoCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.theme['secondaryColor'],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.theme['textColor'],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsersView() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final headerHeight = 120.0;
        final tableHeaderHeight = 60.0;
        final paginationHeight = 80.0;
        final containerPadding = 80.0;
        final tableTopRadius = 16.0;

        final availableHeight = constraints.maxHeight - headerHeight - tableHeaderHeight - paginationHeight - containerPadding - tableTopRadius;
        final rowHeight = 77.0;

        _itemsPerPage = (availableHeight / rowHeight).floor();
        if (_itemsPerPage < 1) _itemsPerPage = 1;

        _totalPages = (_filteredUsers.length / _itemsPerPage).ceil();
        if (_totalPages == 0) _totalPages = 1;
        if (_currentPage > _totalPages) _currentPage = _totalPages;

        return Container(
          padding: const EdgeInsets.all(40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Users Management',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.theme['textColor'],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${_filteredUsers.length} users found',
                          style: TextStyle(
                            fontSize: 15,
                            color: AppColors.theme['secondaryColor'],
                          ),
                        ),
                      ],
                    ),
                  ),
              const SizedBox(width: 20),
              Container(
                width: 200,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.2),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    isExpanded: true,
                    icon: Icon(Icons.filter_list_rounded, color: AppColors.theme['primaryColor']),
                    items: [
                      const DropdownMenuItem(value: 'all', child: Text('All Roles')),
                      ...UserTypes.allTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(UserTypes.getLabel(type)),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _roleFilter = value!;
                        _currentPage = 1;
                        _filterUsers();
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 280,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.2),
                  ),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search users...',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    prefixIcon: Icon(Icons.search, color: AppColors.theme['secondaryColor'], size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _isLoadingUsers ? null : _fetchUsers,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
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
                    child: _isLoadingUsers
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.refresh, color: Colors.white, size: 20),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoadingUsers
                ? Center(
                    child: CircularProgressIndicator(
                      color: AppColors.theme['primaryColor'],
                    ),
                  )
                : _filteredUsers.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.people_outline,
                              size: 80,
                              color: AppColors.theme['secondaryColor'].withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No users found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                          ],
                        ),
                      )
                    : _buildUsersTable(),
          ),
              const SizedBox(height: 24),
              _buildPagination(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildUsersTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'NAME',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'EMAIL',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'CONTACT',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'ROLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'HOURLY RATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'JOINED',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              for (var i = 0; i < _paginatedUsers.length; i++)
                _buildUserRow(_paginatedUsers[i]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow(UserModel user) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openUserDialog(user),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: AppColors.theme['secondaryColor'].withValues(alpha: 0.08),
                width: 1,
              ),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        user.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.theme['textColor'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  user.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme['secondaryColor'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  user.phone ?? 'N/A',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme['secondaryColor'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Expanded(
                flex: 1,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getRoleColor(user.userType).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      UserTypes.getLabel(user.userType),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _getRoleColor(user.userType),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  '\$${user.hourlyRate.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.theme['textColor'],
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Text(
                  user.createdAt != null
                      ? _formatDateShort(DateTime.parse(user.createdAt!))
                      : 'N/A',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.theme['secondaryColor'],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'admin':
        return const Color(0xFFA65899);
      case 'project_manager':
        return const Color(0xFF3B82F6);
      case 'team_member':
        return const Color(0xFF10B981);
      case 'sales':
        return const Color(0xFFF59E0B);
      case 'guest':
        return const Color(0xFF6B7280);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildPagination() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: _currentPage > 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                    });
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _currentPage > 1 ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _currentPage > 1
                      ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 20,
                    color: _currentPage > 1
                        ? AppColors.theme['primaryColor']
                        : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Previous',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _currentPage > 1
                          ? AppColors.theme['primaryColor']
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ...List.generate(
          _totalPages > 5 ? 5 : _totalPages,
          (index) {
            int pageNumber;
            if (_totalPages <= 5) {
              pageNumber = index + 1;
            } else if (_currentPage <= 3) {
              pageNumber = index + 1;
            } else if (_currentPage >= _totalPages - 2) {
              pageNumber = _totalPages - 4 + index;
            } else {
              pageNumber = _currentPage - 2 + index;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _currentPage = pageNumber;
                    });
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: _currentPage == pageNumber
                          ? LinearGradient(
                              colors: [
                                AppColors.theme['primaryColor'],
                                (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                              ],
                            )
                          : null,
                      color: _currentPage != pageNumber ? Colors.white : null,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: _currentPage == pageNumber
                            ? AppColors.theme['primaryColor']
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$pageNumber',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: _currentPage == pageNumber
                              ? Colors.white
                              : AppColors.theme['textColor'],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(width: 16),
        MouseRegion(
          cursor: _currentPage < _totalPages ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                    });
                  }
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: _currentPage < _totalPages ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _currentPage < _totalPages
                      ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Text(
                    'Next',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _currentPage < _totalPages
                          ? AppColors.theme['primaryColor']
                          : Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: _currentPage < _totalPages
                        ? AppColors.theme['primaryColor']
                        : Colors.grey.shade400,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserDetailsDialog(UserModel user) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: 900,
        height: 500,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.2),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 350,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.theme['primaryColor'],
                    (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 25,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.name.isNotEmpty ? user.name[0].toUpperCase() : 'U',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppColors.theme['primaryColor'],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white.withValues(alpha: 0.95),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setDialogState) {
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'User Details',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.theme['textColor'],
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    Icons.close,
                                    color: AppColors.theme['primaryColor'],
                                    size: 22,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Information',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['textColor'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDetailCard(
                            Icons.phone_rounded,
                            'Phone',
                            user.phone ?? 'Not provided',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildStatusCard(user),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildDetailCard(
                      Icons.calendar_today_rounded,
                      'Joined',
                      user.createdAt != null
                          ? _formatDate(DateTime.parse(user.createdAt!))
                          : 'N/A',
                    ),
                    const SizedBox(height: 28),
                    Text(
                      'Update User',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['textColor'],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Role',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.theme['secondaryColor'],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: AppColors.theme['backgroundColor'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _selectedRole,
                                    isExpanded: true,
                                    icon: Icon(Icons.arrow_drop_down, color: AppColors.theme['primaryColor']),
                                    items: UserTypes.allTypes.map((String type) {
                                      return DropdownMenuItem<String>(
                                        value: type,
                                        child: Text(
                                          UserTypes.getLabel(type),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: AppColors.theme['textColor'],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _selectedRole = newValue;
                                      });
                                      setDialogState(() {
                                        _selectedRole = newValue;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hourly Rate (\$)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.theme['secondaryColor'],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                height: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.theme['backgroundColor'],
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.2),
                                  ),
                                ),
                                child: TextField(
                                  controller: _hourlyRateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Enter hourly rate',
                                    hintStyle: TextStyle(
                                      color: AppColors.theme['secondaryColor'],
                                      fontSize: 14,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                                    prefixIcon: Icon(
                                      Icons.attach_money,
                                      color: AppColors.theme['primaryColor'],
                                    ),
                                  ),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: AppColors.theme['textColor'],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _isUpdating ? null : () => _updateUser(user, context),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
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
                          child: _isUpdating
                              ? const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Update User',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                        ),
                      ),
                    ),
                    SizedBox(height: 20,)
                  ],
                ),
              ),
            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(UserModel user) {
    final isActive = user.isActive;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.theme['backgroundColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Pulsing outer circle
                    if (isActive)
                      Container(
                        width: 20 * _pulseAnimation.value,
                        height: 20 * _pulseAnimation.value,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.green.withValues(alpha: 0.3 * (1 - _pulseAnimation.value + 0.6)),
                        ),
                      ),
                    // Inner dot
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive ? Colors.green : Colors.red,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Status',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.theme['secondaryColor'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.theme['backgroundColor'],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.theme['primaryColor'], size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.theme['secondaryColor'],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? AppColors.theme['textColor'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatDateShort(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year.toString().substring(2)}';
  }
}

// Admin Expenses View
class AdminExpensesView extends StatefulWidget {
  const AdminExpensesView({super.key});

  @override
  State<AdminExpensesView> createState() => _AdminExpensesViewState();
}

class _AdminExpensesViewState extends State<AdminExpensesView> {
  List<ExpenseModel> _expenses = [];
  List<ExpenseModel> _filteredExpenses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'Approved'; // Show only Approved expenses by default
  String _sortBy = 'createdAt';
  bool _sortAscending = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
        _filterAndSortExpenses();
      });
    });
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    try {
      setState(() => _isLoading = true);
      final expenses = await ExpenseService.getAllExpenses();
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _filterAndSortExpenses();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Failed to load expenses');
      }
    }
  }

  void _filterAndSortExpenses() {
    var filtered = _expenses;

    // Apply status filter
    if (_statusFilter != 'All Status') {
      filtered = filtered.where((expense) => expense.status == _statusFilter).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((expense) {
        return expense.name.toLowerCase().contains(query) ||
            expense.description.toLowerCase().contains(query) ||
            expense.projectName.toLowerCase().contains(query) ||
            expense.submitterName.toLowerCase().contains(query);
      }).toList();
    }

    // Apply sorting
    filtered.sort((a, b) {
      int comparison = 0;
      switch (_sortBy) {
        case 'amount':
          comparison = a.amount.compareTo(b.amount);
          break;
        case 'name':
          comparison = a.name.compareTo(b.name);
          break;
        case 'createdAt':
        default:
          comparison = (a.createdAt ?? DateTime.now()).compareTo(b.createdAt ?? DateTime.now());
      }
      return _sortAscending ? comparison : -comparison;
    });

    setState(() {
      _filteredExpenses = filtered;
    });
  }

  Future<void> _approveExpense(ExpenseModel expense) async {
    try {
      final updated = await ExpenseService.updateExpenseStatus(expense.id, 'Reimbursed');
      if (updated != null && mounted) {
        AppToast.showSuccess(context, 'Expense marked as reimbursed');
        _loadExpenses();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to approve expense');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error: $e');
      }
    }
  }

  Future<void> _rejectExpense(ExpenseModel expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.warning_rounded, color: Color(0xFFEF4444), size: 32),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reject Expense?',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to reject "${expense.name}"?',
                style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      try {
        final updated = await ExpenseService.updateExpenseStatus(expense.id, 'RejectedByAdmin');
        if (updated != null && mounted) {
          AppToast.showSuccess(context, 'Expense rejected by admin');
          _loadExpenses();
        } else if (mounted) {
          AppToast.showError(context, 'Failed to reject expense');
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(context, 'Error: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses Management',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.theme['textColor'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review and approve project expenses',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.theme['secondaryColor'],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                // Controls Row
                Row(
                  children: [
                    // Search Bar
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name, description, project, or submitter...',
                            hintStyle: TextStyle(color: AppColors.theme['secondaryColor']),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.theme['secondaryColor']),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                    },
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort By
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _sortBy,
                          icon: Icon(Icons.sort_rounded, color: AppColors.theme['primaryColor']),
                          items: const [
                            DropdownMenuItem(value: 'createdAt', child: Text('Date')),
                            DropdownMenuItem(value: 'amount', child: Text('Amount')),
                            DropdownMenuItem(value: 'name', child: Text('Name')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _sortBy = value!;
                              _filterAndSortExpenses();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Sort Direction
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                            _filterAndSortExpenses();
                          });
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            _sortAscending ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                            color: AppColors.theme['primaryColor'],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Status Filter
                    Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _statusFilter,
                          icon: Icon(Icons.filter_list_rounded, color: AppColors.theme['primaryColor']),
                          items: ['All Status', ...ExpenseStatus.allStatuses].map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(status == 'All Status' ? status : ExpenseStatus.getLabel(status)),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _statusFilter = value!;
                              _filterAndSortExpenses();
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Refresh Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _loadExpenses,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Icon(
                            Icons.refresh_rounded,
                            color: AppColors.theme['primaryColor'],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Expenses List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredExpenses.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No expenses found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredExpenses.length,
                        itemBuilder: (context, index) {
                          return _buildExpenseCard(_filteredExpenses[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final statusColor = _getExpenseStatusColor(expense.status);
    final canApproveOrReject = expense.status == 'Approved';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.theme['textColor'],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expense.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.theme['secondaryColor'],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '\$${expense.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['primaryColor'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        ExpenseStatus.getLabel(expense.status),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildInfoChip(Icons.folder_rounded, expense.projectName),
                const SizedBox(width: 12),
                _buildInfoChip(Icons.calendar_month, expense.expensePeriod),
                const SizedBox(width: 12),
                Tooltip(
                  message: '${expense.submittedBy?.roleLabel ?? 'User'}\n${expense.submittedBy?.email ?? ''}',
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  preferBelow: false,
                  child: _buildInfoChip(Icons.person, expense.submitterName),
                ),
                const SizedBox(width: 12),
                if (expense.billable)
                  _buildInfoChip(Icons.check_circle, 'Billable'),
              ],
            ),
            // Approve/Reject buttons for Approved status
            if (canApproveOrReject) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _approveExpense(expense),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF10B981), Color(0xFF059669)],
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Reimburse',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _rejectExpense(expense),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFEF4444)),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.cancel, color: Color(0xFFEF4444), size: 18),
                              SizedBox(width: 6),
                              Text(
                                'Reject by Admin',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getExpenseStatusColor(String status) {
    switch (status) {
      case 'Submitted':
        return const Color(0xFF3B82F6);
      case 'Approved':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      case 'RejectedByAdmin':
        return const Color(0xFFDC2626);
      case 'Reimbursed':
        return const Color(0xFFA65899);
      default:
        return const Color(0xFF64748B);
    }
  }
}
