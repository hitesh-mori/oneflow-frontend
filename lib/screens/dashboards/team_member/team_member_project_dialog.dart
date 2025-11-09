import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../../../models/expense_model.dart';
import '../../../models/order_model.dart';
import '../../../services/task_service.dart';
import '../../../services/expense_service.dart';
import '../../../services/order_service.dart';
import '../../../services/toast_service.dart';
import '../../../core/theme/app_colors.dart';
import '../project_manager/project_dialog_views.dart';

class TeamMemberProjectDialog extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onProjectUpdated;

  const TeamMemberProjectDialog({
    super.key,
    required this.project,
    required this.onProjectUpdated,
  });

  @override
  State<TeamMemberProjectDialog> createState() => _TeamMemberProjectDialogState();
}

class _TeamMemberProjectDialogState extends State<TeamMemberProjectDialog> {
  String _selectedTab = 'tasks';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 1200,
        height: 700,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            // Sidebar
            Container(
              width: 250,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFA65899), Color(0xFF8B4A7F)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 32),
                  Container(
                    width: 80,
                    height: 80,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.folder_rounded,
                      size: 40,
                      color: Color(0xFFA65899),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      widget.project.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 32),
                  _buildTabButton('My Tasks', Icons.task_alt_rounded, 'tasks'),
                  _buildTabButton('Log Hours', Icons.access_time_rounded, 'hours'),
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
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Text(
                            'Close',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Main content
            Expanded(
              child: _selectedTab == 'tasks'
                  ? MyTasksView(project: widget.project)
                  : _selectedTab == 'hours'
                      ? LogHoursView(project: widget.project)
                      : _selectedTab == 'expenses'
                          ? TeamMemberExpensesTabView(project: widget.project)
                          : _selectedTab == 'sales_orders'
                              ? ProjectOrdersView(project: widget.project, orderType: 'Sales')
                              : ProjectOrdersView(project: widget.project, orderType: 'Purchase'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, String value) {
    final isSelected = _selectedTab == value;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => setState(() => _selectedTab = value),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: isSelected
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isSelected
                  ? Border.all(color: Colors.white.withValues(alpha: 0.3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

// My Tasks View with Kanban Board
class MyTasksView extends StatefulWidget {
  final ProjectModel project;

  const MyTasksView({super.key, required this.project});

  @override
  State<MyTasksView> createState() => _MyTasksViewState();
}

class _MyTasksViewState extends State<MyTasksView> {
  List<TaskModel> _tasks = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    _loadTasks();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTasks() async {
    setState(() => _isLoading = true);
    try {
      final result = await TaskService.getTasksForProject(
        widget.project.id,
        myTasks: true,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _tasks = result['tasks'] as List<TaskModel>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Failed to load tasks: ${e.toString()}');
      }
    }
  }

  List<TaskModel> _getTasksByState(String state) {
    return _tasks.where((task) {
      final matchesState = task.state == state;
      if (_searchQuery.isEmpty) return matchesState;

      final query = _searchQuery.toLowerCase();
      final matchesTitle = task.title.toLowerCase().contains(query);
      final matchesDescription = task.description?.toLowerCase().contains(query) ?? false;

      return matchesState && (matchesTitle || matchesDescription);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header with search and refresh button
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search tasks by title or description...',
                        hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                        prefixIcon: const Icon(Icons.search, color: Color(0xFFA65899), size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => _searchController.clear(),
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
                    onTap: _loadTasks,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFA65899), width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.shade200,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.refresh_rounded, color: Color(0xFFA65899), size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Kanban board
          Expanded(
            child: _isLoading
                ? _buildKanbanShimmer()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      spacing: 12,
                      children: [
                        _buildKanbanColumn('New', TaskState.newTask, const Color(0xFF6B7280)),
                        _buildKanbanColumn('In Progress', TaskState.inProgress, const Color(0xFF3B82F6)),
                        _buildKanbanColumn('Blocked', TaskState.blocked, const Color(0xFFEF4444)),
                        _buildKanbanColumn('Done', TaskState.done, const Color(0xFF10B981)),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKanbanColumn(String title, String state, Color color) {
    final tasks = _getTasksByState(state);

    return Expanded(
      child: DragTarget<TaskModel>(
        onWillAcceptWithDetails: (details) => details.data.state != state,
        onAcceptWithDetails: (details) => _updateTaskState(details.data, state),
        builder: (context, candidateData, rejectedData) {
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: candidateData.isNotEmpty ? color : const Color(0xFFE2E8F0),
                width: candidateData.isNotEmpty ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${tasks.length}',
                          style: TextStyle(
                            color: color,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                          child: Text(
                            'No tasks',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 14,
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) => _buildTaskCard(tasks[index]),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = _getPriorityColor(task.priority);
    final stateColor = _getStateColor(task.state);

    return Draggable<TaskModel>(
      data: task,
      feedback: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: stateColor.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: _buildTaskCardContent(task, priorityColor),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContainer(task, priorityColor),
      ),
      child: _buildTaskCardContainer(task, priorityColor),
    );
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'new':
        return const Color(0xFF6B7280);
      case 'in_progress':
        return const Color(0xFF3B82F6);
      case 'blocked':
        return const Color(0xFFEF4444);
      case 'done':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF6B7280);
    }
  }

  Widget _buildTaskCardContainer(TaskModel task, Color priorityColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: _buildTaskCardContent(task, priorityColor),
    );
  }

  Widget _buildTaskCardContent(TaskModel task, Color priorityColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: priorityColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: priorityColor.withValues(alpha: 0.3)),
              ),
              child: Text(
                TaskPriority.getLabel(task.priority),
                style: TextStyle(
                  color: priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (task.isOverdue)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_rounded, size: 10, color: Color(0xFFEF4444)),
                    SizedBox(width: 4),
                    Text(
                      'Overdue',
                      style: TextStyle(
                        color: Color(0xFFEF4444),
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task.title,
          style: const TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (task.description != null && task.description!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            task.description!,
            style: const TextStyle(
              color: Color(0xFF64748B),
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            if (task.dueDate != null) ...[
              const Icon(Icons.calendar_today_rounded, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                DateFormat('MMM dd').format(task.dueDate!),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
            ],
            if (task.assignees.isNotEmpty) ...[
              const Icon(Icons.person_rounded, size: 12, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                '${task.assignees.length}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
        if (task.estimateHours > 0) ...[
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: task.estimateHours > 0
                  ? (task.totalLoggedHours / task.estimateHours).clamp(0.0, 1.0)
                  : 0.0,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(
                task.isOverEstimate ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
              minHeight: 4,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${task.totalLoggedHours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
              Text(
                '/ ${task.estimateHours.toStringAsFixed(1)}h',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  Future<void> _updateTaskState(TaskModel task, String newState) async {
    try {
      final updatedTask = await TaskService.updateTaskState(task.id, newState);
      if (updatedTask != null && mounted) {
        AppToast.showSuccess(context, 'Task state updated successfully');
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to update task state: ${e.toString()}');
      }
    }
  }

  Widget _buildKanbanShimmer() {
    return Row(
      children: List.generate(
        4,
        (index) => Expanded(
          child: Container(
            margin: const EdgeInsets.all(12),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Column(
                children: [
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Log Hours View
class LogHoursView extends StatefulWidget {
  final ProjectModel project;

  const LogHoursView({super.key, required this.project});

  @override
  State<LogHoursView> createState() => _LogHoursViewState();
}

class _LogHoursViewState extends State<LogHoursView> {
  List<TaskModel> _myTasks = [];
  Map<String, List<TimeLogModel>> _timeLogsByTask = {};
  bool _isLoading = true;
  String _searchQuery = '';
  TaskModel? _selectedTask;

  @override
  void initState() {
    super.initState();
    _loadMyTasks();
  }

  Future<void> _loadMyTasks() async {
    setState(() => _isLoading = true);
    try {
      final result = await TaskService.getTasksForProject(
        widget.project.id,
        myTasks: true,
        limit: 100,
      );

      if (mounted) {
        setState(() {
          _myTasks = result['tasks'] as List<TaskModel>;
          _isLoading = false;
        });

        // Load time logs for all tasks
        for (final task in _myTasks) {
          _loadTimeLogsForTask(task.id);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppToast.showError(context, 'Failed to load tasks: ${e.toString()}');
      }
    }
  }

  Future<void> _loadTimeLogsForTask(String taskId) async {
    try {
      final logs = await TaskService.getTimeLogs(taskId, myLogs: true);
      if (mounted) {
        setState(() {
          _timeLogsByTask[taskId] = logs;
        });
      }
    } catch (e) {
      print('Failed to load time logs for task $taskId: $e');
    }
  }

  List<TaskModel> get _filteredTasks {
    if (_searchQuery.isEmpty) return _myTasks;
    return _myTasks.where((task) =>
      task.title.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          _buildLogHoursHeader(),
          Expanded(
            child: _isLoading ? _buildLoadingShimmer() : _buildLogHoursContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLogHoursHeader() {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: _showAddTimeLogDialog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFA65899), Color(0xFF8B4A7F)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFA65899).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Log Time',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: const InputDecoration(
                  hintText: 'Search tasks...',
                  prefixIcon: Icon(Icons.search_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogHoursContent() {
    if (_filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_rounded,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks assigned to you',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: _filteredTasks.length,
      itemBuilder: (context, index) => _buildTaskTimeLogCard(_filteredTasks[index]),
    );
  }

  Widget _buildTaskTimeLogCard(TaskModel task) {
    final timeLogs = _timeLogsByTask[task.id] ?? [];
    final totalHours = timeLogs.fold<double>(0, (sum, log) => sum + log.hours);
    final totalCost = timeLogs.fold<double>(0, (sum, log) => sum + log.calculatedCost);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _getPriorityColor(task.priority).withValues(alpha: 0.1),
                  _getPriorityColor(task.priority).withValues(alpha: 0.05),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.task_rounded,
                    color: _getPriorityColor(task.priority),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getPriorityColor(task.priority).withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              TaskPriority.getLabel(task.priority),
                              style: TextStyle(
                                color: _getPriorityColor(task.priority),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Total: ${totalHours.toStringAsFixed(1)}h',
                            style: const TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (task.estimateHours > 0) ...[
                            const SizedBox(width: 4),
                            Text(
                              '/ ${task.estimateHours.toStringAsFixed(1)}h',
                              style: const TextStyle(
                                color: Color(0xFF94A3B8),
                                fontSize: 13,
                              ),
                            ),
                          ],
                          if (totalCost > 0) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFA65899).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '\$${totalCost.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Color(0xFFA65899),
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedTask = task);
                      _showAddTimeLogDialog();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFA65899), Color(0xFF8B4A7F)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (timeLogs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'No time logged yet',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: timeLogs.length,
              itemBuilder: (context, index) => _buildTimeLogItem(task, timeLogs[index]),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeLogItem(TaskModel task, TimeLogModel log) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFA65899).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.access_time_rounded, color: Color(0xFFA65899), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${log.hours.toStringAsFixed(1)}h',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (log.calculatedCost > 0) ...[
                      Text(
                        '\$${log.calculatedCost.toStringAsFixed(2)}',
                        style: const TextStyle(
                          color: Color(0xFFA65899),
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: log.billable
                            ? const Color(0xFF10B981).withValues(alpha: 0.1)
                            : const Color(0xFF64748B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        log.billable ? 'Billable' : 'Non-billable',
                        style: TextStyle(
                          color: log.billable ? const Color(0xFF10B981) : const Color(0xFF64748B),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, size: 12, color: Colors.grey[400]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(log.date),
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                      ),
                    ),
                    if (log.note != null && log.note!.isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Icon(Icons.notes_rounded, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          log.note!,
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _deleteTimeLog(task, log),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return const Color(0xFFEF4444);
      case 'high':
        return const Color(0xFFF59E0B);
      case 'medium':
        return const Color(0xFF3B82F6);
      case 'low':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF64748B);
    }
  }

  void _showAddTimeLogDialog() {
    showDialog(
      context: context,
      builder: (context) => AddTimeLogDialog(
        tasks: _myTasks,
        selectedTask: _selectedTask,
        onTimeLogged: (taskId) {
          _loadTimeLogsForTask(taskId);
          _loadMyTasks();
        },
      ),
    );
  }

  Future<void> _deleteTimeLog(TaskModel task, TimeLogModel log) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_rounded,
                  color: Color(0xFFEF4444),
                  size: 40,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Delete Time Log',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 12),
              // Message
              Text(
                'Are you sure you want to delete this time log? This action cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context, false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Cancel',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
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
                        onTap: () => Navigator.pop(context, true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: const Text(
                            'Delete',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
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

    if (confirm == true && log.id != null) {
      try {
        final success = await TaskService.deleteTimeLog(task.id, log.id!);
        if (success && mounted) {
          AppToast.showSuccess(context, 'Time log deleted successfully');
          _loadTimeLogsForTask(task.id);
          _loadMyTasks();
        }
      } catch (e) {
        if (mounted) {
          AppToast.showError(context, 'Failed to delete time log: ${e.toString()}');
        }
      }
    }
  }

  Widget _buildLoadingShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(24.0),
      itemCount: 3,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: Container(
          height: 120,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// Add Time Log Dialog
class AddTimeLogDialog extends StatefulWidget {
  final List<TaskModel> tasks;
  final TaskModel? selectedTask;
  final Function(String taskId) onTimeLogged;

  const AddTimeLogDialog({
    super.key,
    required this.tasks,
    this.selectedTask,
    required this.onTimeLogged,
  });

  @override
  State<AddTimeLogDialog> createState() => _AddTimeLogDialogState();
}

class _AddTimeLogDialogState extends State<AddTimeLogDialog> {
  final _hoursController = TextEditingController();
  final _noteController = TextEditingController();
  TaskModel? _selectedTask;
  DateTime _selectedDate = DateTime.now();
  bool _isBillable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedTask = widget.selectedTask;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        constraints: const BoxConstraints(maxHeight: 650),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Purple gradient header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFA65899), Color(0xFF8B4A7F)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.access_time_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      'Log Time',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.close, color: Colors.white, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Form content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Task',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: DropdownButton<TaskModel>(
                        value: _selectedTask,
                        isExpanded: true,
                        underline: const SizedBox(),
                        hint: const Text('Select a task'),
                        items: widget.tasks.map((task) {
                          return DropdownMenuItem(
                            value: task,
                            child: Text(task.title),
                          );
                        }).toList(),
                        onChanged: (value) => setState(() => _selectedTask = value),
                      ),
                    ),
            const SizedBox(height: 16),
            const Text(
              'Hours',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _hoursController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: 'Enter hours (e.g., 2.5)',
                  prefixIcon: Icon(Icons.access_time_rounded, color: Color(0xFF64748B)),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded, color: Color(0xFF64748B), size: 20),
                      const SizedBox(width: 12),
                      Text(
                        DateFormat('MMM dd, yyyy').format(_selectedDate),
                        style: const TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: TextField(
                controller: _noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Add a note about this work...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _isBillable = !_isBillable),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: _isBillable ? const Color(0xFF3B82F6) : Colors.white,
                        border: Border.all(
                          color: _isBillable ? const Color(0xFF3B82F6) : const Color(0xFFE2E8F0),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: _isBillable
                          ? const Icon(Icons.check, color: Colors.white, size: 14)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Billable',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  color: Color(0xFF64748B),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: _isLoading ? null : _logTime,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFA65899), Color(0xFF8B4A7F)],
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFA65899).withValues(alpha: 0.3),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Row(
                                      children: [
                                        Icon(Icons.check_rounded, color: Colors.white, size: 18),
                                        SizedBox(width: 8),
                                        Text(
                                          'Log Time',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logTime() async {
    if (_selectedTask == null) {
      AppToast.showError(context, 'Please select a task');
      return;
    }

    final hours = double.tryParse(_hoursController.text);
    if (hours == null || hours <= 0) {
      AppToast.showError(context, 'Please enter valid hours');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final updatedTask = await TaskService.logTime(
        _selectedTask!.id,
        hours: hours,
        date: _selectedDate,
        billable: _isBillable,
        note: _noteController.text.isEmpty ? null : _noteController.text,
      );

      if (updatedTask != null && mounted) {
        AppToast.showSuccess(context, 'Time logged successfully');
        widget.onTimeLogged(_selectedTask!.id);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Failed to log time: ${e.toString()}');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _hoursController.dispose();
    _noteController.dispose();
    super.dispose();
  }
}

// Team Member Expenses Tab View
class TeamMemberExpensesTabView extends StatefulWidget {
  final ProjectModel project;

  const TeamMemberExpensesTabView({super.key, required this.project});

  @override
  State<TeamMemberExpensesTabView> createState() => _TeamMemberExpensesTabViewState();
}

class _TeamMemberExpensesTabViewState extends State<TeamMemberExpensesTabView> {
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
    try {
      setState(() => _isLoading = true);
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
        AppToast.showError(context, 'Failed to load expenses');
      }
    }
  }

  List<ExpenseModel> get _filteredExpenses {
    if (_searchQuery.isEmpty) return _expenses;
    final query = _searchQuery.toLowerCase();
    return _expenses.where((expense) {
      return expense.name.toLowerCase().contains(query) ||
          expense.description.toLowerCase().contains(query);
    }).toList();
  }

  void _showAddExpenseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AddTeamMemberExpenseDialog(
        project: widget.project,
        onAdded: _loadExpenses,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          // Header with search and add button
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  AppColors.theme['primaryColor'].withValues(alpha: 0.02),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.theme['primaryColor'].withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.theme['primaryColor'].withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
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
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _showAddExpenseDialog,
                    child: Container(
                      height: 45,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.theme['primaryColor'],
                            AppColors.theme['primaryColor'].withValues(alpha: 0.8),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.theme['primaryColor'].withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
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
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
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
                              size: 64,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isEmpty ? 'No expenses yet' : 'No matching expenses',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Click "Add Expense" to create your first expense'
                                  : 'Try adjusting your search',
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
    final submitterName = expense.submitterName.isNotEmpty ? expense.submitterName : 'Unknown';
    final email = expense.submitterEmail;

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
            // Header
            Row(
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
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.4),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
            const SizedBox(height: 8),
            Text(
              expense.description,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.theme['secondaryColor'],
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            // Amount
            Row(
              children: [
                Icon(
                  Icons.payments_rounded,
                  size: 22,
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
            const SizedBox(height: 16),
            // Info chips row
            Row(
              children: [
                // Period chip
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.calendar_month, size: 14, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            expense.expensePeriod,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF64748B),
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
                const SizedBox(width: 8),
                // Billable badge
                if (expense.billable)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Color(0xFF10B981)),
                        SizedBox(width: 4),
                        Text(
                          'Billable',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 12),
            // Enhanced submitter card
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
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.6),
                        ],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        submitterName[0].toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Submitted by',
                          style: TextStyle(
                            fontSize: 9,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          submitterName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF1E293B),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (email.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF94A3B8),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.theme['secondaryColor']),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.theme['secondaryColor'],
              fontWeight: FontWeight.w500,
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

// Add Team Member Expense Dialog
class AddTeamMemberExpenseDialog extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onAdded;

  const AddTeamMemberExpenseDialog({
    super.key,
    required this.project,
    required this.onAdded,
  });

  @override
  State<AddTeamMemberExpenseDialog> createState() => _AddTeamMemberExpenseDialogState();
}

class _AddTeamMemberExpenseDialogState extends State<AddTeamMemberExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _amountController = TextEditingController();
  final _periodController = TextEditingController();
  bool _billable = true;
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
        'status': 'Submitted', // Team members submit directly
      };

      final expense = await ExpenseService.createExpense(expenseData);

      if (expense != null && mounted) {
        AppToast.showSuccess(context, 'Expense submitted successfully');
        widget.onAdded();
        Navigator.of(context).pop();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to submit expense');
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error: $e');
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
        constraints: const BoxConstraints(maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.theme['primaryColor'],
                    AppColors.theme['primaryColor'].withValues(alpha: 0.8),
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
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
                    child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Add Expense',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Submit expense for approval',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Expense Name
                      const Text(
                        'Expense Name',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'e.g., Office Supplies, Travel Expense',
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
                      // Amount
                      const Text(
                        'Amount (\$)',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          hintText: '0.00',
                          prefixIcon: const Icon(Icons.attach_money_rounded),
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
                        validator: (value) {
                          if (value!.trim().isEmpty) return 'Required';
                          if (double.tryParse(value) == null) return 'Invalid amount';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Expense Period
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
                                prefixIcon: const Icon(Icons.calendar_today_rounded),
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
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Description
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
                      // Billable checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _billable,
                            onChanged: (value) => setState(() => _billable = value ?? true),
                            activeColor: AppColors.theme['primaryColor'],
                          ),
                          const Text(
                            'Billable to client',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Buttons
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
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Text(
                                    'Cancel',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black54,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
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
                                        AppColors.theme['primaryColor'].withValues(alpha: 0.8),
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
                                              'Submit Expense',
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
