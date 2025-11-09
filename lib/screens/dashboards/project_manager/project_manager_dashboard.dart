import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/routing/route_constants.dart';
import '../../../providers/auth_provider.dart';
import '../../../services/toast_service.dart';
import '../../../services/project_service.dart';
import '../../../services/api_service.dart';
import '../../../services/expense_service.dart';
import '../../../models/project_model.dart';
import '../../../models/user_model.dart';
import '../../../models/expense_model.dart';
import 'project_dialog_views.dart';

class ProjectManagerDashboard extends StatefulWidget {
  const ProjectManagerDashboard({super.key});

  @override
  State<ProjectManagerDashboard> createState() => _ProjectManagerDashboardState();
}

class _ProjectManagerDashboardState extends State<ProjectManagerDashboard> {
  String _selectedMenu = 'projects';
  List<ProjectModel> _projects = [];
  List<ProjectModel> _filteredProjects = [];
  bool _isLoadingProjects = false;

  final TextEditingController _searchController = TextEditingController();
  String _sortBy = 'endDate';
  bool _sortAscending = true;
  String _statusFilter = 'all';

  String? _lastFetchedManagerId;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterProjects);
    print("#init");
    // Don't fetch here - will fetch in build when user is available
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchProjects() async {
    if (!mounted) return;

    print('🔍 Dashboard: Starting to fetch projects...');
    setState(() => _isLoadingProjects = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final managerId = authProvider.user?.id;

      if (managerId == null) {
        print('❌ Dashboard: Manager ID not found');
        if (mounted) {
          setState(() => _isLoadingProjects = false);
          AppToast.showError(context, 'Manager ID not found. Please login again.');
        }
        return;
      }

      print('🔍 Dashboard: Fetching projects for manager: $managerId');
      final projects = await ProjectService.getManagerProjects(managerId);
      print('🔍 Dashboard: Received ${projects.length} projects');

      if (!mounted) return;

      setState(() {
        _projects = projects;
        print('🔍 Dashboard: Set _projects to ${_projects.length} items');
        _filterProjects();
        _isLoadingProjects = false;
      });
      print('🔍 Dashboard: After filtering, have ${_filteredProjects.length} filtered projects');
    } catch (e) {
      print('❌ Dashboard: Error fetching projects - $e');
      if (mounted) {
        setState(() => _isLoadingProjects = false);
        AppToast.showError(context, 'Failed to load projects: $e');
      }
    }
  }

  void _filterProjects() {
    final query = _searchController.text.toLowerCase();
    List<ProjectModel> filtered = _projects.where((project) {
      final matchesSearch = project.name.toLowerCase().contains(query) ||
          (project.description?.toLowerCase().contains(query) ?? false);
      final matchesStatus = _statusFilter == 'all' || project.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    if (_sortBy == 'endDate') {
      filtered.sort((a, b) {
        final aDate = a.endDate ?? DateTime(2099);
        final bDate = b.endDate ?? DateTime(2099);
        return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
    } else if (_sortBy == 'startDate') {
      filtered.sort((a, b) {
        final aDate = a.startDate ?? DateTime(2000);
        final bDate = b.startDate ?? DateTime(2000);
        return _sortAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
    }

    setState(() {
      _filteredProjects = filtered;
    });
  }

  void _openProjectDialog(ProjectModel project) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return ProjectDetailsDialog(
          project: project,
          onUpdate: _fetchProjects,
        );
      },
    );
  }

  void _openCreateProjectDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return CreateProjectDialog(onCreated: _fetchProjects);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final manager = authProvider.user;

    // Fetch projects when user becomes available
    if (manager?.id != null && _lastFetchedManagerId != manager!.id) {
      print("🔄 User available, fetching projects for: ${manager.id}");
      _lastFetchedManagerId = manager.id;
      Future.microtask(() => _fetchProjects());
    }

    return Scaffold(
      backgroundColor: AppColors.theme['backgroundColor'],
      body: Row(
        children: [
          _buildSidebar(manager),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildSidebar(UserModel? manager) {
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/images/oneflow.png', height: 60, width: 60, color: Colors.white),
                      Text("ONEFLOW", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.theme['cardColor'], fontSize: 20)),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 8))],
                  ),
                  child: Center(
                    child: Text(
                      (manager?.name.isNotEmpty ?? false) ? manager!.name[0].toUpperCase() : 'P',
                      style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.theme['primaryColor']),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(manager?.name ?? 'Project Manager', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Text(manager?.email ?? '', style: TextStyle(fontSize: 12, color: Colors.white.withValues(alpha: 0.9)), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 7),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                  ),
                  child: const Text('Project Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 0.5)),
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
                    child: Text('MENU', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.theme['secondaryColor'], letterSpacing: 1.5)),
                  ),
                  _buildMenuItem(icon: Icons.folder_rounded, title: 'Projects', isActive: _selectedMenu == 'projects', onTap: () => setState(() => _selectedMenu = 'projects')),
                  _buildMenuItem(icon: Icons.receipt_long_rounded, title: 'Expenses', isActive: _selectedMenu == 'expenses', onTap: () => setState(() => _selectedMenu = 'expenses')),
                  _buildMenuItem(icon: Icons.dashboard_rounded, title: 'Dashboard', isActive: _selectedMenu == 'dashboard', onTap: () => setState(() => _selectedMenu = 'dashboard')),
                  _buildMenuItem(icon: Icons.person_rounded, title: 'Profile', isActive: _selectedMenu == 'profile', onTap: () => setState(() => _selectedMenu = 'profile')),
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
                    gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [Icon(Icons.logout_rounded, color: Colors.white, size: 20), SizedBox(width: 10), Text('Logout', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.5))],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, bool isActive = false, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isActive ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(icon, size: 22, color: isActive ? AppColors.theme['primaryColor'] : AppColors.theme['secondaryColor']),
                const SizedBox(width: 14),
                Text(title, style: TextStyle(fontSize: 15, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500, color: isActive ? AppColors.theme['primaryColor'] : AppColors.theme['textColor'])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedMenu == 'projects') {
      return _buildProjectsView();
    } else if (_selectedMenu == 'dashboard') {
      return _buildDashboardView();
    } else if (_selectedMenu == 'expenses') {
      return _buildExpensesView();
    } else if (_selectedMenu == 'profile') {
      return _buildProfileView();
    }
    return const SizedBox();
  }

  Widget _buildDashboardView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dashboard Overview', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
          const SizedBox(height: 32),
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            crossAxisSpacing: 24,
            mainAxisSpacing: 24,
            childAspectRatio: 1.5,
            children: [
              _buildDashboardCard('Total Projects', _projects.length.toString(), Icons.folder_rounded, const Color(0xFF3B82F6)),
              _buildDashboardCard('Active', _projects.where((p) => p.status == 'active').length.toString(), Icons.play_circle_rounded, const Color(0xFF10B981)),
              _buildDashboardCard('Completed', _projects.where((p) => p.status == 'completed').length.toString(), Icons.check_circle_rounded, const Color(0xFFA65899)),
              _buildDashboardCard('Planned', _projects.where((p) => p.status == 'planned').length.toString(), Icons.schedule_rounded, const Color(0xFFF59E0B)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 14, color: AppColors.theme['secondaryColor'], fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(value, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsView() {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header with Title and Stats
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
                      padding: const EdgeInsets.all(12),
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
                      child: const Icon(Icons.folder_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Projects',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.theme['textColor'],
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Manage and track all your projects',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.theme['secondaryColor'],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(height: 1),
                const SizedBox(height: 20),
                // Controls Row
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          // Search Bar (First Priority)
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
                                  hintText: 'Search projects by name or description...',
                                  hintStyle: const TextStyle(
                                    color: Color(0xFF94A3B8),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                  prefixIcon: Icon(
                                    Icons.search_rounded,
                                    color: AppColors.theme['primaryColor'],
                                    size: 22,
                                  ),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () => _searchController.clear(),
                                            child: const Icon(
                                              Icons.clear_rounded,
                                              color: Color(0xFF94A3B8),
                                              size: 20,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort Dropdown
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
                                icon: Icon(
                                  Icons.unfold_more_rounded,
                                  color: AppColors.theme['primaryColor'],
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: AppColors.theme['textColor'],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: const [
                                  DropdownMenuItem(
                                    value: 'endDate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.event_rounded, size: 18, color: Color(0xFF64748B)),
                                        SizedBox(width: 8),
                                        Text('Deadline'),
                                      ],
                                    ),
                                  ),
                                  DropdownMenuItem(
                                    value: 'startDate',
                                    child: Row(
                                      children: [
                                        Icon(Icons.calendar_today_rounded, size: 18, color: Color(0xFF64748B)),
                                        SizedBox(width: 8),
                                        Text('Start Date'),
                                      ],
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(() {
                                  _sortBy = value!;
                                  _filterProjects();
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Sort Direction Toggle
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => setState(() {
                                _sortAscending = !_sortAscending;
                                _filterProjects();
                              }),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: Icon(
                                  _sortAscending
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: AppColors.theme['primaryColor'],
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Status Filter
                          Container(
                            width: 160,
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
                                isExpanded: true,
                                icon: Icon(
                                  Icons.filter_list_rounded,
                                  color: AppColors.theme['primaryColor'],
                                  size: 20,
                                ),
                                style: TextStyle(
                                  color: AppColors.theme['textColor'],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                                items: [
                                  const DropdownMenuItem(
                                    value: 'all',
                                    child: Text('All Status'),
                                  ),
                                  ...ProjectStatus.allStatuses.map(
                                    (status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(ProjectStatus.getLabel(status)),
                                    ),
                                  ),
                                ],
                                onChanged: (value) => setState(() {
                                  _statusFilter = value!;
                                  _filterProjects();
                                }),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Refresh Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _fetchProjects,
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
                    const SizedBox(width: 16),
                    // New Project Button
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: _openCreateProjectDialog,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
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
                                color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.add_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 10),
                              Text(
                                'New Project',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: _isLoadingProjects
                ? GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 1.0),
              itemCount: 6,
              itemBuilder: (context, index) => _buildProjectCardShimmer(),
            )
                : _filteredProjects.isEmpty
                ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.folder_open_rounded, size: 80, color: AppColors.theme['secondaryColor'].withValues(alpha: 0.3)), const SizedBox(height: 16), Text('No projects found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.theme['secondaryColor']))]))
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 24, mainAxisSpacing: 24, childAspectRatio: 1.0),
              itemCount: _filteredProjects.length,
              itemBuilder: (context, index) => _buildProjectCard(_filteredProjects[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCard(ProjectModel project) {
    final statusColor = _getStatusColor(project.status);
    final daysRemaining = project.daysRemaining;
    final isOverdue = project.isOverdue;
    final budgetUsedPercent = project.budget > 0 ? (project.costToDate / project.budget * 100).clamp(0, 100) : 0.0;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _openProjectDialog(project),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.grey.shade100, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with gradient background
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      statusColor.withValues(alpha: 0.15),
                      statusColor.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            project.name,
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppColors.theme['textColor'],
                              letterSpacing: -0.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: statusColor,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: statusColor.withValues(alpha: 0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            ProjectStatus.getLabel(project.status),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project.description ?? 'No description provided',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.theme['secondaryColor'],
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Content section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Due date
                      if (project.endDate != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: isOverdue ? Colors.red.shade50 : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOverdue ? Colors.red.shade200 : Colors.blue.shade200,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 12,
                                color: isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isOverdue ? 'Overdue ${-daysRemaining}d' : 'Due in ${daysRemaining}d',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isOverdue ? Colors.red.shade700 : Colors.blue.shade700,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Budget info
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Budget',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.theme['secondaryColor'],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '\$${project.budget.toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.theme['textColor'],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          // Budget progress bar
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: budgetUsedPercent / 100,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: budgetUsedPercent > 90
                                        ? [Colors.red, Colors.red.shade300]
                                        : budgetUsedPercent > 70
                                        ? [Colors.orange, Colors.orange.shade300]
                                        : [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.6)],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '\$${project.costToDate.toStringAsFixed(0)} spent (${budgetUsedPercent.toStringAsFixed(0)}%)',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.theme['secondaryColor'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // Team members
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Team',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.theme['secondaryColor'],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (project.members.isNotEmpty)
                            Row(
                              children: [
                                Stack(
                                  children: [
                                    for (var i = 0; i < (project.members.length > 3 ? 3 : project.members.length); i++)
                                      Padding(
                                        padding: EdgeInsets.only(left: i * 20.0),
                                        child: Tooltip(
                                          message: '${project.members[i].name}\n${project.members[i].email}',
                                          textStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                          decoration: BoxDecoration(
                                            color: Colors.black87,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          waitDuration: const Duration(milliseconds: 300),
                                          child: MouseRegion(
                                            cursor: SystemMouseCursors.click,
                                            child: AnimatedScale(
                                              scale: 1.0,
                                              duration: const Duration(milliseconds: 200),
                                              child: Container(
                                                width: 28,
                                                height: 28,
                                                decoration: BoxDecoration(
                                                  gradient: LinearGradient(
                                                    colors: [
                                                      statusColor,
                                                      statusColor.withValues(alpha: 0.7),
                                                    ],
                                                  ),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(color: Colors.white, width: 2),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black.withValues(alpha: 0.08),
                                                      blurRadius: 3,
                                                      offset: const Offset(0, 1),
                                                    ),
                                                  ],
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    project.members[i].name[0].toUpperCase(),
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    if (project.members.length > 3)
                                      Padding(
                                        padding: const EdgeInsets.only(left: 60),
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            color: AppColors.theme['secondaryColor'],
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.08),
                                                blurRadius: 3,
                                                offset: const Offset(0, 1),
                                              ),
                                            ],
                                          ),
                                          child: Center(
                                            child: Text(
                                              '+${project.members.length - 3}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            )
                          else
                            Text(
                              'No members',
                              style: TextStyle(
                                fontSize: 10,
                                color: AppColors.theme['secondaryColor'],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'planned': return const Color(0xFFF59E0B);
      case 'active': return const Color(0xFF10B981);
      case 'on_hold': return const Color(0xFF6B7280);
      case 'completed': return const Color(0xFFA65899);
      case 'cancelled': return const Color(0xFFEF4444);
      default: return const Color(0xFF6B7280);
    }
  }

  Widget _buildExpensesView() {
    return GeneralExpensesView();
  }

  Widget _buildProfileView() {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

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
                        colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7)],
                      ),
                      boxShadow: [BoxShadow(color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3), blurRadius: 30, offset: const Offset(0, 15))],
                    ),
                    child: Center(child: Text((user?.name.isNotEmpty ?? false) ? user!.name[0].toUpperCase() : 'P', style: const TextStyle(fontSize: 56, fontWeight: FontWeight.bold, color: Colors.white))),
                  ),
                  const SizedBox(width: 40),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'Project Manager', style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
                        const SizedBox(height: 8),
                        Text(user?.email ?? '', style: TextStyle(fontSize: 18, color: AppColors.theme['secondaryColor'])),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                              decoration: BoxDecoration(gradient: LinearGradient(colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8)]), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]),
                              child: const Text('Project Manager', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14, letterSpacing: 0.5)),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(25), border: Border.all(color: Colors.green.shade200, width: 1.5)),
                              child: Row(children: [Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)), const SizedBox(width: 8), Text('Active', style: TextStyle(color: Colors.green.shade700, fontWeight: FontWeight.w600, fontSize: 14))]),
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
                  _buildProfileInfoCard(Icons.email_rounded, 'Email', user?.email ?? 'N/A', Colors.blue),
                  _buildProfileInfoCard(Icons.phone_rounded, 'Phone', user?.phone ?? 'Not provided', Colors.green),
                  _buildProfileInfoCard(Icons.attach_money_rounded, 'Hourly Rate', '\$${user?.hourlyRate ?? 0}/hr', Colors.orange),
                  _buildProfileInfoCard(Icons.calendar_today_rounded, 'Last Login', user?.lastLogin != null ? _formatDate(user!.lastLogin!) : 'N/A', Colors.purple),
                  _buildProfileInfoCard(Icons.schedule_rounded, 'Joined', user?.createdAt != null ? _formatDate(DateTime.parse(user!.createdAt!)) : 'N/A', Colors.indigo),
                  _buildProfileInfoCard(Icons.folder_rounded, 'Projects', _projects.length.toString(), const Color(0xFFA65899)),
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
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: color.withValues(alpha: 0.1), blurRadius: 20, offset: const Offset(0, 10))], border: Border.all(color: color.withValues(alpha: 0.2), width: 1)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, color: color, size: 28)),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: TextStyle(fontSize: 12, color: AppColors.theme['secondaryColor'], fontWeight: FontWeight.w500)), const SizedBox(height: 6), Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.theme['textColor']), maxLines: 1, overflow: TextOverflow.ellipsis)]),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildProjectCardShimmer() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header shimmer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 17,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        width: 60,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Shimmer.fromColors(
                  baseColor: Colors.grey.shade300,
                  highlightColor: Colors.grey.shade100,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content shimmer
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Due date shimmer
                  Shimmer.fromColors(
                    baseColor: Colors.grey.shade300,
                    highlightColor: Colors.grey.shade100,
                    child: Container(
                      width: 100,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Budget shimmer
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 50,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          Shimmer.fromColors(
                            baseColor: Colors.grey.shade300,
                            highlightColor: Colors.grey.shade100,
                            child: Container(
                              width: 70,
                              height: 18,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Progress bar shimmer
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          height: 6,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 100,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // Team members shimmer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Container(
                          width: 40,
                          height: 11,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: EdgeInsets.only(left: i * 20.0),
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey.shade300,
                                highlightColor: Colors.grey.shade100,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// PROJECT DETAILS DIALOG - Will be created next
class ProjectDetailsDialog extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onUpdate;

  const ProjectDetailsDialog({super.key, required this.project, required this.onUpdate});

  @override
  State<ProjectDetailsDialog> createState() => _ProjectDetailsDialogState();
}

class _ProjectDetailsDialogState extends State<ProjectDetailsDialog> {
  String _selectedTab = 'edit';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1200,
        height: 700,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
        child: Row(
          children: [
            Container(
              width: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(width: 80, height: 80, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle), child: Icon(Icons.folder_rounded, size: 40, color: AppColors.theme['primaryColor'])),
                  const SizedBox(height: 16),
                  Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text(widget.project.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis)),
                  const SizedBox(height: 32),
                  _buildTabButton('Edit Project', Icons.edit_rounded, 'edit'),
                  _buildTabButton('Tasks', Icons.task_alt_rounded, 'tasks'),
                  _buildTabButton('Team Members', Icons.people_rounded, 'members'),
                  _buildTabButton('Expenses', Icons.receipt_long_rounded, 'expenses'),
                  _buildTabButton('Sales Orders', Icons.shopping_cart_outlined, 'sales_orders'),
                  _buildTabButton('Purchase Orders', Icons.shopping_bag_outlined, 'purchase_orders'),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.white.withValues(alpha: 0.3))),
                          child: const Text('Close', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), textAlign: TextAlign.center),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _selectedTab == 'edit'
                  ? EditProjectView(project: widget.project, onUpdate: widget.onUpdate)
                  : _selectedTab == 'tasks'
                      ? TasksView(project: widget.project)
                      : _selectedTab == 'members'
                          ? TeamMembersView(project: widget.project)
                          : _selectedTab == 'expenses'
                              ? ExpensesView(project: widget.project)
                              : _selectedTab == 'sales_orders'
                                  ? ProjectOrdersView(project: widget.project, orderType: 'Sales')
                                  : ProjectOrdersView(project: widget.project, orderType: 'Purchase'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, IconData icon, String tab) {
    final isActive = _selectedTab == tab;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _selectedTab = tab),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(color: isActive ? Colors.white.withValues(alpha: 0.2) : Colors.transparent, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [Icon(icon, color: Colors.white, size: 20), const SizedBox(width: 12), Text(title, style: TextStyle(color: Colors.white, fontWeight: isActive ? FontWeight.bold : FontWeight.w500, fontSize: 14))]),
          ),
        ),
      ),
    );
  }
}

// CREATE PROJECT DIALOG
class CreateProjectDialog extends StatefulWidget {
  final VoidCallback onCreated;
  const CreateProjectDialog({super.key, required this.onCreated});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _budgetController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planned';
  bool _isCreating = false;
  List<UserModel> _allUsers = [];
  List<String> _selectedMembers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _budgetController.dispose();
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
          setState(() {
            _allUsers = usersData.map((u) => UserModel.fromJson(u)).where((u) => u.userType == 'team_member').toList();
            _isLoadingUsers = false;
          });
        }
      }
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate end date is after start date
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      if (mounted) {
        AppToast.showError(context, 'End date must be after start date');
      }
      return;
    }

    setState(() => _isCreating = true);
    try {
      final projectData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        'budget': double.tryParse(_budgetController.text) ?? 0,
        'status': _status,
        'members': _selectedMembers,
        'links': [],
      };

      final project = await ProjectService.createProject(projectData);
      if (project != null && mounted) {
        AppToast.showSuccess(context, 'Project created successfully');
        Navigator.of(context).pop();
        widget.onCreated();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to create project');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 750,
        constraints: const BoxConstraints(maxHeight: 700),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Modern header with gradient
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.theme['primaryColor'],
                    (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add_circle_outline, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Create New Project',
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, size: 22, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Form content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Project Name *',
                          hintText: 'Enter project name',
                          prefixIcon: Icon(Icons.folder_outlined, color: AppColors.theme['primaryColor']),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                          ),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _descController,
                        decoration: InputDecoration(
                          labelText: 'Description',
                          hintText: 'Enter project description',
                          prefixIcon: Icon(Icons.description_outlined, color: AppColors.theme['primaryColor']),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                          ),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _budgetController,
                        decoration: InputDecoration(
                          labelText: 'Budget (\$)',
                          hintText: 'Enter budget amount',
                          prefixIcon: Icon(Icons.attach_money, color: AppColors.theme['primaryColor']),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                          ),
                        ),
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
                                if (date != null) setState(() => _startDate = date);
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Start Date',
                                  prefixIcon: Icon(Icons.calendar_today_outlined, color: AppColors.theme['primaryColor'], size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                                  ),
                                ),
                                child: Text(
                                  _startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : 'Select date',
                                  style: TextStyle(color: _startDate != null ? Colors.black : Colors.grey.shade600, fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () async {
                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: _startDate != null && DateTime.now().isBefore(_startDate!)
                                      ? _startDate!.add(const Duration(days: 1))
                                      : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
                                  firstDate: _startDate ?? DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (date != null) {
                                  if (_startDate != null && date.isBefore(_startDate!)) {
                                    if (mounted) {
                                      AppToast.showError(context, 'End date must be after start date');
                                    }
                                  } else {
                                    setState(() => _endDate = date);
                                  }
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'End Date',
                                  prefixIcon: Icon(Icons.event_outlined, color: AppColors.theme['primaryColor'], size: 20),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                                  filled: true,
                                  fillColor: Colors.grey.shade50,
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey.shade200),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                                  ),
                                  errorText: _endDate != null && _startDate != null && _endDate!.isBefore(_startDate!)
                                      ? 'Must be after start date'
                                      : null,
                                ),
                                child: Text(
                                  _endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'Select date',
                                  style: TextStyle(color: _endDate != null ? Colors.black : Colors.grey.shade600, fontSize: 15),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade300),
                                ),
                                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600, fontSize: 15)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          MouseRegion(
                            cursor: SystemMouseCursors.click,
                            child: GestureDetector(
                              onTap: _isCreating ? null : _createProject,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8)],
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
                                child: _isCreating
                                    ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(Colors.white)),
                                )
                                    : const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                                    SizedBox(width: 8),
                                    Text('Create Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                                  ],
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
          ],
        ),
      ),
    );
  }
}

// EXPENSES VIEW
class ExpensesView extends StatefulWidget {
  final ProjectModel project;

  const ExpensesView({super.key, required this.project});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadExpenses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    setState(() => _isLoading = true);
    try {
      final expenses = await ExpenseService.getProjectExpenses(widget.project.id);
      if (mounted) {
        setState(() {
          _expenses = expenses;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Failed to load expenses: $e');
      }
    }
  }

  List<ExpenseModel> get _filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;
    return _expenses.where((expense) {
      final query = _searchQuery.toLowerCase();
      return expense.name.toLowerCase().contains(query) ||
          expense.description.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddExpenseDialog(
        project: widget.project,
        onAdded: _loadExpenses,
      ),
    );
  }

  Future<void> _deleteExpense(ExpenseModel expense) async {
    // Show modern delete confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  size: 40,
                  color: Color(0xFFEF4444),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Delete Expense',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to delete "${expense.name}"? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF64748B),
                            ),
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
                        onTap: () => Navigator.of(context).pop(true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Delete',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
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
    );

    if (confirmed == true) {
      try {
        final success = await ExpenseService.deleteExpense(expense.id);
        if (success && mounted) {
          AppToast.showSuccess(context, 'Expense deleted successfully');
          _loadExpenses();
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(context, 'Failed to delete expense: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF5F7FA),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with search and add button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 45,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search expenses...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFA65899), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    setState(() => _searchQuery = '');
                                  },
                                  child: const Icon(Icons.clear, color: Color(0xFF94A3B8), size: 20),
                                ),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _loadExpenses,
                    child: Container(
                      width: 45,
                      height: 45,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
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
                const SizedBox(width: 12),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showAddExpenseDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.add, color: Colors.white, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Add Expense',
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
              ],
            ),
          ),
          // Expenses list
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
                              color: (AppColors.theme['secondaryColor'] as Color).withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No expenses yet' : 'No expenses found',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 1.8,
                        ),
                        itemCount: _filteredExpenses.length,
                        itemBuilder: (context, index) {
                          final expense = _filteredExpenses[index];
                          return _buildExpenseCard(expense);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(ExpenseModel expense) {
    final statusColor = _getStatusColor(expense.status);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  expense.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  ExpenseStatus.getLabel(expense.status),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            expense.description,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Amount
          Row(
            children: [
              Icon(
                Icons.payments_rounded,
                size: 20,
                color: AppColors.theme['primaryColor'],
              ),
              const SizedBox(width: 8),
              Text(
                '\$${expense.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.theme['primaryColor'],
                ),
              ),
            ],
          ),
          const Spacer(),
          // Info section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info chips row
              Row(
                children: [
                  // Project
                  if (expense.projectName != null && expense.projectName!.isNotEmpty)
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.folder_rounded, size: 14, color: AppColors.theme['secondaryColor']),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                expense.projectName!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.theme['secondaryColor'],
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (expense.projectName != null && expense.projectName!.isNotEmpty) const SizedBox(width: 8),
                  // Billable badge
                  if (expense.billable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                          const SizedBox(width: 4),
                          const Text(
                            'Billable',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF10B981),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Period chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.theme['secondaryColor']),
                    const SizedBox(width: 4),
                    Text(
                      expense.expensePeriod,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.theme['secondaryColor'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Submitter with enhanced styling
              if (expense.submitterName.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
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
                            expense.submitterName.isNotEmpty ? expense.submitterName[0].toUpperCase() : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Submitted by',
                              style: TextStyle(
                                fontSize: 9,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                            Text(
                              expense.submitterName,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.theme['textColor'],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (expense.submitterEmail.isNotEmpty)
                              Text(
                                expense.submitterEmail,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          // Approve/Reject buttons for Submitted expenses
          if (expense.status == 'Submitted') ...[
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
                              'Approve',
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
                              'Reject',
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
    );
  }

  Future<void> _approveExpense(ExpenseModel expense) async {
    try {
      final updated = await ExpenseService.updateExpenseStatus(expense.id, 'Approved');
      if (updated != null && mounted) {
        AppToast.showSuccess(context, 'Expense approved successfully');
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
    // Show confirmation dialog
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
                child: const Icon(
                  Icons.warning_rounded,
                  color: Color(0xFFEF4444),
                  size: 32,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Reject Expense?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to reject "${expense.name}"?',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF64748B),
                ),
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
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
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
        final updated = await ExpenseService.updateExpenseStatus(expense.id, 'Rejected');
        if (updated != null && mounted) {
          AppToast.showSuccess(context, 'Expense rejected');
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

  Widget _buildPMDetailItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
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

  Color _getStatusColor(String status) {
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

// ADD EXPENSE DIALOG
class AddExpenseDialog extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onAdded;

  const AddExpenseDialog({super.key, required this.project, required this.onAdded});

  @override
  State<AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends State<AddExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _periodController = TextEditingController();
  bool _billable = true;
  String _status = 'Approved'; // Project managers' expenses are auto-approved
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _amountController.dispose();
    _periodController.dispose();
    super.dispose();
  }

  Future<void> _submitExpense() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final expenseData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        'expensePeriod': _periodController.text.trim(),
        'project': widget.project.id,
        'amount': double.parse(_amountController.text),
        'billable': _billable,
        'status': _status,
      };

      final expense = await ExpenseService.createExpense(expenseData);
      if (expense != null && mounted) {
        AppToast.showSuccess(context, 'Expense added successfully');
        widget.onAdded();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to add expense: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.theme['primaryColor'],
                        (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Add Expense',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.close, size: 20),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Flexible(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Expense Name',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Office Supplies',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                          ),
                        ),
                        validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Amount',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: 'Enter amount (e.g., 150.50)',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          prefixIcon: const Icon(Icons.attach_money, size: 20),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value!.trim().isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Expense Period',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: DateTime.now(),
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                              builder: (context, child) {
                                return Theme(
                                  data: Theme.of(context).copyWith(
                                    colorScheme: ColorScheme.light(
                                      primary: AppColors.theme['primaryColor'],
                                      onPrimary: Colors.white,
                                      onSurface: Colors.black,
                                    ),
                                  ),
                                  child: child!,
                                );
                              },
                            );
                            if (picked != null) {
                              final formattedDate = DateFormat('MMM yyyy').format(picked);
                              setState(() {
                                _periodController.text = formattedDate;
                              });
                            }
                          },
                          child: AbsorbPointer(
                            child: TextFormField(
                              controller: _periodController,
                              decoration: InputDecoration(
                                hintText: 'Select expense period',
                                filled: true,
                                fillColor: const Color(0xFFF8FAFC),
                                prefixIcon: const Icon(Icons.calendar_month, size: 20),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: Colors.grey.shade200),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                                ),
                              ),
                              validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Description',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          hintText: 'Add details about this expense...',
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppColors.theme['primaryColor'], width: 2),
                          ),
                        ),
                        validator: (value) => value!.trim().isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Checkbox(
                            value: _billable,
                            onChanged: (value) => setState(() => _billable = value ?? true),
                            activeColor: AppColors.theme['primaryColor'],
                          ),
                          const Text(
                            'Billable',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.of(context).pop(),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF1F5F9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF64748B),
                                    ),
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
                                onTap: _isSubmitting ? null : _submitExpense,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        AppColors.theme['primaryColor'],
                                        (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _isSubmitting
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation(Colors.white),
                                            ),
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check, color: Colors.white, size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              'Add Expense',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
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
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// General Expenses View - Shows all expenses across all projects
class GeneralExpensesView extends StatefulWidget {
  const GeneralExpensesView({super.key});

  @override
  State<GeneralExpensesView> createState() => _GeneralExpensesViewState();
}

class _GeneralExpensesViewState extends State<GeneralExpensesView> {
  List<ExpenseModel> _expenses = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'All Status';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
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
      final expenses = await ExpenseService.getMyExpenses();
      if (mounted) {
        setState(() {
          _expenses = expenses;
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

  List<ExpenseModel> get _filteredExpenses {
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
            expense.projectName.toLowerCase().contains(query);
      }).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Modern Header
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
                            'Expenses',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.theme['textColor'],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Track and manage all project expenses',
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
                          onChanged: (value) => setState(() => _searchQuery = value),
                          decoration: InputDecoration(
                            hintText: 'Search expenses...',
                            hintStyle: TextStyle(color: AppColors.theme['secondaryColor']),
                            prefixIcon: Icon(Icons.search_rounded, color: AppColors.theme['secondaryColor']),
                            suffixIcon: _searchQuery.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchQuery = '');
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
                          icon: Icon(Icons.arrow_drop_down, color: AppColors.theme['primaryColor']),
                          items: ['All Status', ...ExpenseStatus.allStatuses].map((status) {
                            return DropdownMenuItem(value: status, child: Text(status));
                          }).toList(),
                          onChanged: (value) => setState(() => _statusFilter = value!),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Refresh Button
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.refresh_rounded, color: AppColors.theme['primaryColor']),
                        onPressed: _loadExpenses,
                        tooltip: 'Refresh',
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
                              _searchQuery.isEmpty && _statusFilter == 'All Status'
                                  ? 'No expenses found'
                                  : 'No matching expenses',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty && _statusFilter == 'All Status'
                                  ? 'Expenses will appear here once added to projects'
                                  : 'Try adjusting your search or filters',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                          childAspectRatio: 1.8,
                        ),
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

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with gradient
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  statusColor.withValues(alpha: 0.15),
                  statusColor.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        expense.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.theme['textColor'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        expense.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  expense.description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.theme['secondaryColor'],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount
                  Row(
                    children: [
                      Icon(Icons.attach_money_rounded, size: 18, color: AppColors.theme['secondaryColor']),
                      const SizedBox(width: 6),
                      Text(
                        '\$${expense.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.theme['primaryColor'],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Info section
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info chips row
                      Row(
                        children: [
                          // Project
                          if (expense.projectName.isNotEmpty)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.folder_rounded, size: 14, color: AppColors.theme['secondaryColor']),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        expense.projectName,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.theme['secondaryColor'],
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (expense.projectName.isNotEmpty) const SizedBox(width: 8),
                          // Billable badge
                          if (expense.billable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'Billable',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Color(0xFF10B981),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Period chip
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.theme['secondaryColor']),
                            const SizedBox(width: 4),
                            Text(
                              expense.expensePeriod,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.theme['secondaryColor'],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Submitter with enhanced styling
                      if (expense.submitterName.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
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
                                    expense.submitterName.isNotEmpty ? expense.submitterName[0].toUpperCase() : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Submitted by',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Color(0xFF94A3B8),
                                      ),
                                    ),
                                    Text(
                                      expense.submitterName,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.theme['textColor'],
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (expense.submitterEmail.isNotEmpty)
                                      Text(
                                        expense.submitterEmail,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          color: Color(0xFF94A3B8),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                  ],
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
