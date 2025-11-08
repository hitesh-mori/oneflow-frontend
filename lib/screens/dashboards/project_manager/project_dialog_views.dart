import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../services/toast_service.dart';
import '../../../services/project_service.dart';
import '../../../services/task_service.dart';
import '../../../services/api_service.dart';
import '../../../models/project_model.dart';
import '../../../models/task_model.dart';
import '../../../models/user_model.dart';

// EDIT PROJECT VIEW
class EditProjectView extends StatefulWidget {
  final ProjectModel project;
  final VoidCallback onUpdate;

  const EditProjectView({super.key, required this.project, required this.onUpdate});

  @override
  State<EditProjectView> createState() => _EditProjectViewState();
}

class _EditProjectViewState extends State<EditProjectView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _budgetController;
  DateTime? _startDate;
  DateTime? _endDate;
  String _status = 'planned';
  bool _isUpdating = false;
  List<UserModel> _allUsers = [];
  List<String> _selectedMembers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.project.name);
    _descController = TextEditingController(text: widget.project.description ?? '');
    _budgetController = TextEditingController(text: widget.project.budget.toString());
    _startDate = widget.project.startDate;
    _endDate = widget.project.endDate;
    _status = widget.project.status;
    _selectedMembers = widget.project.members.map((m) => m.id).toList();
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

  Future<void> _updateProject() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate end date is after start date
    if (_startDate != null && _endDate != null && _endDate!.isBefore(_startDate!)) {
      if (mounted) {
        AppToast.showError(context, 'End date must be after start date');
      }
      return;
    }

    setState(() => _isUpdating = true);
    try {
      print('🔄 Updating project with members: $_selectedMembers');
      print('🔄 Members type: ${_selectedMembers.runtimeType}');

      final updateData = {
        'name': _nameController.text.trim(),
        'description': _descController.text.trim(),
        if (_startDate != null) 'startDate': _startDate!.toIso8601String(),
        if (_endDate != null) 'endDate': _endDate!.toIso8601String(),
        'budget': double.tryParse(_budgetController.text) ?? 0,
        'status': _status,
        'members': _selectedMembers,
      };

      print('🔄 Update data: $updateData');
      final project = await ProjectService.updateProject(widget.project.id, updateData);
      if (project != null && mounted) {
        AppToast.showSuccess(context, 'Project updated successfully');
        widget.onUpdate();
        Navigator.of(context).pop();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to update project');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  Future<void> _deleteProject() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project'),
        content: const Text('Are you sure you want to delete this project? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await ProjectService.deleteProject(widget.project.id);
        if (success && mounted) {
          AppToast.showSuccess(context, 'Project deleted successfully');
          Navigator.of(context).pop();
          widget.onUpdate();
        } else if (mounted) {
          AppToast.showError(context, 'Failed to delete project');
        }
      } catch (e) {
        if (mounted) AppToast.showError(context, 'Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit Project', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
            const SizedBox(height: 24),
            _buildTextField('Project Name', _nameController, 'Enter project name', required: true),
            const SizedBox(height: 16),
            _buildTextField('Description', _descController, 'Enter description', maxLines: 4),
            const SizedBox(height: 16),
            _buildTextField('Budget (\$)', _budgetController, 'Enter budget', keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStartDateField()),
                const SizedBox(width: 16),
                Expanded(child: _buildEndDateField()),
              ],
            ),
            const SizedBox(height: 16),
            _buildStatusDropdown(),
            const SizedBox(height: 24),
            Text('Team Members', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.theme['textColor'])),
            const SizedBox(height: 12),
            _isLoadingUsers
                ? Center(child: buildCircularShimmer(size: 30))
                : _buildTeamMembersSelector(),
            const SizedBox(height: 32),
            Row(
              children: [
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _deleteProject,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline, color: Colors.red.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text('Delete Project', style: TextStyle(color: Colors.red.shade700, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: _isUpdating ? null : _updateProject,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: _isUpdating
                          ? buildCircularShimmer(size: 20)
                          : const Text('Update Project', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, {bool required = false, int maxLines = 1, TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      validator: required ? (v) => v == null || v.isEmpty ? 'Required' : null : null,
    );
  }

  Widget _buildDateField(String label, DateTime? date, Function(DateTime) onSelect) {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (selected != null) onSelect(selected);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(date != null ? '${date.day}/${date.month}/${date.year}' : 'Select date', style: TextStyle(color: date != null ? Colors.black : Colors.grey.shade600)),
            Icon(Icons.calendar_today, size: 18, color: AppColors.theme['primaryColor']),
          ],
        ),
      ),
    );
  }

  Widget _buildStartDateField() {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: _startDate ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (selected != null) {
          setState(() {
            _startDate = selected;
            // If end date is before new start date, clear it
            if (_endDate != null && _endDate!.isBefore(selected)) {
              _endDate = null;
            }
          });
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Start Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_startDate != null ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}' : 'Select date', style: TextStyle(color: _startDate != null ? Colors.black : Colors.grey.shade600)),
            Icon(Icons.calendar_today, size: 18, color: AppColors.theme['primaryColor']),
          ],
        ),
      ),
    );
  }

  Widget _buildEndDateField() {
    return InkWell(
      onTap: () async {
        final selected = await showDatePicker(
          context: context,
          initialDate: _startDate != null && DateTime.now().isBefore(_startDate!)
              ? _startDate!.add(const Duration(days: 1))
              : (_startDate ?? DateTime.now()).add(const Duration(days: 1)),
          firstDate: _startDate ?? DateTime(2020),
          lastDate: DateTime(2030),
        );
        if (selected != null) {
          if (_startDate != null && selected.isBefore(_startDate!)) {
            if (mounted) {
              AppToast.showError(context, 'End date must be after start date');
            }
          } else {
            setState(() => _endDate = selected);
          }
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'End Date',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Colors.grey.shade50,
          errorText: _endDate != null && _startDate != null && _endDate!.isBefore(_startDate!)
              ? 'Must be after start date'
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_endDate != null ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}' : 'Select date', style: TextStyle(color: _endDate != null ? Colors.black : Colors.grey.shade600)),
            Icon(Icons.calendar_today, size: 18, color: AppColors.theme['primaryColor']),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _status,
      decoration: InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      items: ProjectStatus.allStatuses.map((status) => DropdownMenuItem(value: status, child: Text(ProjectStatus.getLabel(status)))).toList(),
      onChanged: (value) => setState(() => _status = value!),
    );
  }

  Widget _buildTeamMembersSelector() {
    final TextEditingController searchController = TextEditingController();
    List<UserModel> filteredUsers = _allUsers;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and dropdown container
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search team members...',
                        prefixIcon: Icon(Icons.search, color: AppColors.theme['primaryColor']),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setLocalState(() {
                          filteredUsers = _allUsers
                              .where((user) =>
                                  user.name.toLowerCase().contains(value.toLowerCase()) ||
                                  user.email.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  // Members list
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        final isSelected = _selectedMembers.contains(user.id);
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  _selectedMembers.remove(user.id);
                                } else {
                                  _selectedMembers.add(user.id!);
                                }
                              });
                              setLocalState(() {});
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.05) : Colors.transparent,
                                border: Border(
                                  top: index == 0 ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isSelected ? AppColors.theme['primaryColor'] : Colors.white,
                                      border: Border.all(
                                        color: isSelected ? AppColors.theme['primaryColor'] as Color : Colors.grey.shade400,
                                        width: 2,
                                      ),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: isSelected
                                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Container(
                                    width: 36,
                                    height: 36,
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
                                        user.name[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          user.name,
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.theme['textColor'],
                                          ),
                                        ),
                                        Text(
                                          user.email,
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.theme['secondaryColor'],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Selected members chips
            if (_selectedMembers.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Selected Members (${_selectedMembers.length})',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.theme['secondaryColor'],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedMembers.map((memberId) {
                  final user = _allUsers.firstWhere((u) => u.id == memberId);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedMembers.remove(memberId));
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}

// TASKS VIEW
class TasksView extends StatefulWidget {
  final ProjectModel project;

  const TasksView({super.key, required this.project});

  @override
  State<TasksView> createState() => _TasksViewState();
}

class _TasksViewState extends State<TasksView> {
  List<TaskModel> _tasks = [];
  List<TaskModel> _filteredTasks = [];
  bool _isLoading = false;
  bool _showAddTaskForm = false;
  final TextEditingController _searchController = TextEditingController();
  bool _hasSearchText = false;

  @override
  void initState() {
    super.initState();
    _fetchTasks();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _hasSearchText = _searchController.text.isNotEmpty;
    });
    _filterTasks();
  }

  Future<void> _fetchTasks() async {
    setState(() => _isLoading = true);
    try {
      final result = await TaskService.getTasksForProject(widget.project.id);
      setState(() {
        _tasks = result['tasks'] as List<TaskModel>;
        _filteredTasks = _tasks;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) AppToast.showError(context, 'Failed to load tasks');
    }
  }

  void _filterTasks() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTasks = _tasks;
      } else {
        _filteredTasks = _tasks.where((task) {
          return task.title.toLowerCase().contains(query) ||
                 (task.description?.toLowerCase().contains(query) ?? false);
        }).toList();
      }
    });
  }

  void _toggleAddTaskForm() {
    setState(() => _showAddTaskForm = !_showAddTaskForm);
  }

  Future<void> _updateTaskState(TaskModel task, String newState) async {
    try {
      print('🔄 Updating task ${task.id} from ${task.state} to $newState');
      final updated = await TaskService.updateTaskState(task.id, newState);
      print('✅ Update response: ${updated != null ? "Success" : "Failed"}');
      if (updated != null && mounted) {
        AppToast.showSuccess(context, 'Task moved to ${TaskState.getLabel(newState)}');
        await _fetchTasks();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to update task');
      }
    } catch (e) {
      print('❌ Update error: $e');
      if (mounted) AppToast.showError(context, 'Failed to update task: $e');
    }
  }

  Future<void> _deleteTask(TaskModel task) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final success = await TaskService.deleteTask(task.id);
        if (success && mounted) {
          AppToast.showSuccess(context, 'Task deleted');
          _fetchTasks();
        }
      } catch (e) {
        if (mounted) AppToast.showError(context, 'Failed to delete task');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Text('Tasks', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
              const SizedBox(width: 24),
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
                      hintStyle: TextStyle(color: AppColors.theme['secondaryColor'], fontSize: 14),
                      prefixIcon: Icon(Icons.search, color: AppColors.theme['primaryColor'], size: 20),
                      suffixIcon: _hasSearchText
                          ? MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _searchController.clear(),
                                child: Icon(Icons.clear, color: AppColors.theme['secondaryColor'], size: 20),
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
                  onTap: _toggleAddTaskForm,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8)]),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(children: [Icon(_showAddTaskForm ? Icons.close : Icons.add, color: Colors.white, size: 18), const SizedBox(width: 8), Text(_showAddTaskForm ? 'Cancel' : 'Add Task', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))]),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              // Kanban board or loading state
              _isLoading
                  ? buildKanbanShimmer()
                  : _buildKanbanBoard(),
              // Add task form overlay
              if (_showAddTaskForm)
                Container(
                  color: Colors.black.withValues(alpha: 0.3),
                  child: Center(
                    child: _buildAddTaskForm(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(TaskModel task) {
    final priorityColor = _getPriorityColor(task.priority);
    final stateColor = _getStateColor(task.state);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.grey.shade100, blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(task.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.theme['textColor']))),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: priorityColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(TaskPriority.getLabel(task.priority), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: priorityColor)),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (value) {
                  if (value == 'delete') _deleteTask(task);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))])),
                ],
              ),
            ],
          ),
          if (task.description != null) ...[
            const SizedBox(height: 8),
            Text(task.description!, style: TextStyle(fontSize: 13, color: AppColors.theme['secondaryColor'])),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: stateColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(TaskState.getLabel(task.state), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: stateColor)),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: task.state,
                underline: const SizedBox(),
                style: TextStyle(fontSize: 12, color: AppColors.theme['textColor']),
                items: TaskState.allStates.map((state) => DropdownMenuItem(value: state, child: Text(TaskState.getLabel(state)))).toList(),
                onChanged: (newState) {
                  if (newState != null) _updateTaskState(task, newState);
                },
              ),
            ],
          ),
          if (task.assignees.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              children: task.assignees.map((assignee) => Chip(label: Text(assignee.name, style: const TextStyle(fontSize: 11)), padding: EdgeInsets.zero, visualDensity: VisualDensity.compact)).toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildKanbanBoard() {
    final newTasks = _filteredTasks.where((t) => t.state == 'new').toList();
    final inProgressTasks = _filteredTasks.where((t) => t.state == 'in_progress').toList();
    final blockedTasks = _filteredTasks.where((t) => t.state == 'blocked').toList();
    final doneTasks = _filteredTasks.where((t) => t.state == 'done').toList();

    return _filteredTasks.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off, size: 64, color: AppColors.theme['secondaryColor'].withValues(alpha: 0.3)),
                const SizedBox(height: 16),
                Text(
                  _searchController.text.isEmpty ? 'No tasks found' : 'No tasks match your search',
                  style: TextStyle(fontSize: 16, color: AppColors.theme['secondaryColor']),
                ),
              ],
            ),
          )
        : Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildKanbanColumn('New', 'new', newTasks, const Color(0xFF6B7280))),
                const SizedBox(width: 16),
                Expanded(child: _buildKanbanColumn('In Progress', 'in_progress', inProgressTasks, const Color(0xFF3B82F6))),
                const SizedBox(width: 16),
                Expanded(child: _buildKanbanColumn('Blocked', 'blocked', blockedTasks, const Color(0xFFEF4444))),
                const SizedBox(width: 16),
                Expanded(child: _buildKanbanColumn('Done', 'done', doneTasks, const Color(0xFF10B981))),
              ],
            ),
          );
  }

  Widget _buildKanbanColumn(String title, String state, List<TaskModel> tasks, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color.withValues(alpha: 0.15), color.withValues(alpha: 0.05)],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
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
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.theme['textColor'],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${tasks.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Tasks list
          Expanded(
            child: DragTarget<TaskModel>(
              onWillAcceptWithDetails: (details) => details.data.state != state,
              onAcceptWithDetails: (details) async {
                await _updateTaskState(details.data, state);
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  decoration: BoxDecoration(
                    color: candidateData.isNotEmpty
                        ? color.withValues(alpha: 0.1)
                        : Colors.transparent,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(14),
                      bottomRight: Radius.circular(14),
                    ),
                  ),
                  child: tasks.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined, size: 48, color: color.withValues(alpha: 0.3)),
                                const SizedBox(height: 12),
                                Text(
                                  'No tasks',
                                  style: TextStyle(
                                    color: AppColors.theme['secondaryColor'],
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) => _buildDraggableTaskCard(tasks[index], color),
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDraggableTaskCard(TaskModel task, Color stateColor) {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                task.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.theme['textColor'],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildTaskCardContent(task, stateColor),
      ),
      child: _buildTaskCardContent(task, stateColor),
    );
  }

  Widget _buildTaskCardContent(TaskModel task, Color stateColor) {
    final priorityColor = _getPriorityColor(task.priority);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  task.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.theme['textColor'],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _deleteTask(task),
                  child: Container(
                    padding: const EdgeInsets.all(4),
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
                    child: const Icon(Icons.delete_rounded, color: Colors.white, size: 14),
                  ),
                ),
              ),
            ],
          ),
          if (task.description != null) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: TextStyle(fontSize: 12, color: AppColors.theme['secondaryColor']),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: priorityColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  TaskPriority.getLabel(task.priority),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: priorityColor,
                  ),
                ),
              ),
              const Spacer(),
              if (task.assignees.isNotEmpty)
                Stack(
                  children: [
                    for (var i = 0; i < (task.assignees.length > 2 ? 2 : task.assignees.length); i++)
                      Padding(
                        padding: EdgeInsets.only(left: i * 16.0),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [stateColor, stateColor.withValues(alpha: 0.7)],
                            ),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              task.assignees[i].name[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (task.assignees.length > 2)
                      Padding(
                        padding: const EdgeInsets.only(left: 32),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.theme['secondaryColor'],
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              '+${task.assignees.length - 2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                              ),
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
    );
  }

  Widget _buildAddTaskForm() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 700, maxHeight: 600),
      margin: const EdgeInsets.all(40),
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
      child: AddTaskInlineForm(
        projectId: widget.project.id,
        project: widget.project,
        onAdded: () {
          _fetchTasks();
          setState(() => _showAddTaskForm = false);
        },
        onCancel: () {
          setState(() => _showAddTaskForm = false);
        },
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent': return const Color(0xFFEF4444);
      case 'high': return const Color(0xFFF59E0B);
      case 'medium': return const Color(0xFF3B82F6);
      case 'low': return const Color(0xFF10B981);
      default: return Colors.grey;
    }
  }

  Color _getStateColor(String state) {
    switch (state) {
      case 'done': return const Color(0xFF10B981);
      case 'in_progress': return const Color(0xFF3B82F6);
      case 'blocked': return const Color(0xFFEF4444);
      case 'new': return const Color(0xFF6B7280);
      default: return Colors.grey;
    }
  }
}

// ADD TASK INLINE FORM
class AddTaskInlineForm extends StatefulWidget {
  final String projectId;
  final VoidCallback onAdded;
  final VoidCallback onCancel;
  final ProjectModel? project;

  const AddTaskInlineForm({
    super.key,
    required this.projectId,
    required this.onAdded,
    required this.onCancel,
    this.project,
  });

  @override
  State<AddTaskInlineForm> createState() => _AddTaskInlineFormState();
}

class _AddTaskInlineFormState extends State<AddTaskInlineForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _estimateController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  List<UserModel> _allUsers = [];
  List<String> _selectedAssignees = [];
  bool _isCreating = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estimateController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      // If project is provided, use project members only
      if (widget.project != null) {
        setState(() {
          _allUsers = widget.project!.members
              .map((m) => UserModel(
                    id: m.id,
                    name: m.name,
                    email: m.email,
                    userType: 'team_member',
                  ))
              .toList();
          _isLoadingUsers = false;
        });
      } else {
        // Fallback to fetching all team members
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
      }
    } catch (e) {
      setState(() => _isLoadingUsers = false);
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      final taskData = {
        'project': widget.projectId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'priority': _priority,
        'estimateHours': double.tryParse(_estimateController.text) ?? 0,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
        'assignees': _selectedAssignees,
      };

      final task = await TaskService.createTask(taskData);
      if (task != null && mounted) {
        AppToast.showSuccess(context, 'Task created successfully');
        widget.onAdded();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to create task');
      }
    } catch (e) {
      if (mounted) AppToast.showError(context, 'Error: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  Widget _buildTeamMembersSelector() {
    final TextEditingController searchController = TextEditingController();
    List<UserModel> filteredUsers = _allUsers;

    return StatefulBuilder(
      builder: (context, setLocalState) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search and dropdown container
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  // Search bar
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search team members...',
                        prefixIcon: Icon(Icons.search, color: AppColors.theme['primaryColor']),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      onChanged: (value) {
                        setLocalState(() {
                          filteredUsers = _allUsers
                              .where((user) =>
                                  user.name.toLowerCase().contains(value.toLowerCase()) ||
                                  user.email.toLowerCase().contains(value.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                  ),
                  // Members list
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: filteredUsers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No team members found')),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filteredUsers.length,
                            itemBuilder: (context, index) {
                              final user = filteredUsers[index];
                              final isSelected = _selectedAssignees.contains(user.id);
                              return MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedAssignees.remove(user.id);
                                      } else {
                                        _selectedAssignees.add(user.id!);
                                      }
                                    });
                                    setLocalState(() {});
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: isSelected ? (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.05) : Colors.transparent,
                                      border: Border(
                                        top: index == 0 ? BorderSide.none : BorderSide(color: Colors.grey.shade200),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 20,
                                          height: 20,
                                          decoration: BoxDecoration(
                                            color: isSelected ? AppColors.theme['primaryColor'] : Colors.white,
                                            border: Border.all(
                                              color: isSelected ? AppColors.theme['primaryColor'] as Color : Colors.grey.shade400,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                                              : null,
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          width: 36,
                                          height: 36,
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
                                              user.name[0].toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.theme['textColor'],
                                                ),
                                              ),
                                              Text(
                                                user.email,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors.theme['secondaryColor'],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            // Selected members chips
            if (_selectedAssignees.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Selected Members (${_selectedAssignees.length})',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.theme['secondaryColor'],
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _selectedAssignees.map((memberId) {
                  final user = _allUsers.firstWhere((u) => u.id == memberId);
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 6),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _selectedAssignees.remove(memberId));
                            },
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Header with close button
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add_task_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Text(
                  'Add New Task',
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
                  onTap: widget.onCancel,
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      labelText: 'Task Title *',
                      hintText: 'Enter task title',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _priority,
                          decoration: InputDecoration(
                            labelText: 'Priority',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          items: TaskPriority.allPriorities
                              .map((p) => DropdownMenuItem(value: p, child: Text(TaskPriority.getLabel(p))))
                              .toList(),
                          onChanged: (v) => setState(() => _priority = v!),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _estimateController,
                          decoration: InputDecoration(
                            labelText: 'Estimate (hours)',
                            hintText: '0',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Team Members',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: AppColors.theme['textColor'],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _isLoadingUsers
                      ? Center(child: buildCircularShimmer(size: 30))
                      : _buildTeamMembersSelector(),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: widget.onCancel,
                        child: const Text('Cancel', style: TextStyle(fontSize: 15)),
                      ),
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _isCreating ? null : _createTask,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
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
                            child: _isCreating
                                ? buildCircularShimmer(size: 20)
                                : const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check, color: Colors.white, size: 20),
                                      SizedBox(width: 8),
                                      Text(
                                        'Create Task',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
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
        ),
      ],
    );
  }
}

// ADD TASK DIALOG (kept for backward compatibility)
class AddTaskDialog extends StatefulWidget {
  final String projectId;
  final VoidCallback onAdded;

  const AddTaskDialog({super.key, required this.projectId, required this.onAdded});

  @override
  State<AddTaskDialog> createState() => _AddTaskDialogState();
}

class _AddTaskDialogState extends State<AddTaskDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _estimateController = TextEditingController();
  String _priority = 'medium';
  DateTime? _dueDate;
  List<UserModel> _allUsers = [];
  List<String> _selectedAssignees = [];
  bool _isCreating = false;
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _estimateController.dispose();
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

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isCreating = true);
    try {
      final taskData = {
        'project': widget.projectId,
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        'priority': _priority,
        'estimateHours': double.tryParse(_estimateController.text) ?? 0,
        if (_dueDate != null) 'dueDate': _dueDate!.toIso8601String(),
        'assignees': _selectedAssignees,
      };

      final task = await TaskService.createTask(taskData);
      if (task != null && mounted) {
        AppToast.showSuccess(context, 'Task created successfully');
        Navigator.of(context).pop();
        widget.onAdded();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to create task');
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Add New Task', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 20),
              TextFormField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title *', border: OutlineInputBorder()), validator: (v) => v == null || v.isEmpty ? 'Required' : null),
              const SizedBox(height: 16),
              TextFormField(controller: _descController, decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()), maxLines: 3),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _priority,
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                      items: TaskPriority.allPriorities.map((p) => DropdownMenuItem(value: p, child: Text(TaskPriority.getLabel(p)))).toList(),
                      onChanged: (v) => setState(() => _priority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: TextFormField(controller: _estimateController, decoration: const InputDecoration(labelText: 'Estimate (hours)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Text('Assignees', style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.theme['textColor'])),
              const SizedBox(height: 8),
              _isLoadingUsers
                  ? Center(child: buildCircularShimmer(size: 30))
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _allUsers.map((user) {
                        final isSelected = _selectedAssignees.contains(user.id);
                        return FilterChip(
                          label: Text(user.name),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (user.id != null) {
                              setState(() => selected ? _selectedAssignees.add(user.id!) : _selectedAssignees.remove(user.id!));
                            }
                          },
                        );
                      }).toList(),
                    ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isCreating ? null : _createTask,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.theme['primaryColor'], padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
                    child: _isCreating ? buildCircularShimmer(size: 20) : const Text('Create Task', style: TextStyle(color: Colors.white)),
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

// TEAM MEMBERS VIEW
class TeamMembersView extends StatefulWidget {
  final ProjectModel project;

  const TeamMembersView({super.key, required this.project});

  @override
  State<TeamMembersView> createState() => _TeamMembersViewState();
}

class _TeamMembersViewState extends State<TeamMembersView> {
  bool _isUnassigning = false;

  Future<void> _unassignMember(String memberId) async {
    setState(() => _isUnassigning = true);
    try {
      final currentMembers = widget.project.members.map((m) => m.id).toList();
      currentMembers.remove(memberId);

      final updateData = {'members': currentMembers};
      final updatedProject = await ProjectService.updateProject(widget.project.id, updateData);

      if (updatedProject != null && mounted) {
        AppToast.showSuccess(context, 'Member unassigned successfully');
        setState(() => _isUnassigning = false);
        // Refresh the view
        Navigator.of(context).pop();
      } else if (mounted) {
        AppToast.showError(context, 'Failed to unassign member');
        setState(() => _isUnassigning = false);
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'Error: $e');
        setState(() => _isUnassigning = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Team Members', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
          const SizedBox(height: 24),
          if (widget.project.manager != null) ...[
            Text('Project Manager', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.theme['secondaryColor'])),
            const SizedBox(height: 12),
            _buildMemberCard(widget.project.manager!, true),
            const SizedBox(height: 24),
          ],
          Text('Team Members (${widget.project.members.length})', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.theme['secondaryColor'])),
          const SizedBox(height: 12),
          if (widget.project.members.isEmpty)
            const Text('No team members assigned')
          else
            ...widget.project.members.map((member) => _buildMemberCard(member, false)),
        ],
      ),
    );
  }

  Widget _buildMemberCard(ProjectMemberModel member, bool isManager) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7)]),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(child: Text(member.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(member.name, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.theme['textColor'])),
                    if (isManager) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(colors: [AppColors.theme['primaryColor'], (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8)]),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Text('Manager', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white)),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(member.email, style: TextStyle(fontSize: 14, color: AppColors.theme['secondaryColor'])),
              ],
            ),
          ),
          if (!isManager) ...[
            const SizedBox(width: 12),
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: _isUnassigning ? null : () => _unassignMember(member.id),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: _isUnassigning
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_remove_rounded, color: Colors.white, size: 16),
                            SizedBox(width: 6),
                            Text('Unassign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// Shimmer Loading Helper Functions
Widget buildShimmerBox({double width = double.infinity, double height = 20, double borderRadius = 8}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    ),
  );
}

Widget buildKanbanShimmer() {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(4, (columnIndex) {
        final colors = [
          const Color(0xFF6B7280),
          const Color(0xFF3B82F6),
          const Color(0xFFEF4444),
          const Color(0xFF10B981),
        ];
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: columnIndex < 3 ? 16 : 0),
            decoration: BoxDecoration(
              color: colors[columnIndex].withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors[columnIndex].withValues(alpha: 0.2), width: 2),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        colors[columnIndex].withValues(alpha: 0.15),
                        colors[columnIndex].withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(14),
                      topRight: Radius.circular(14),
                    ),
                  ),
                  child: Row(
                    children: [
                      buildShimmerBox(width: 80, height: 16, borderRadius: 4),
                      const Spacer(),
                      buildShimmerBox(width: 30, height: 20, borderRadius: 12),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 2,
                    itemBuilder: (context, index) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          buildShimmerBox(width: double.infinity, height: 16, borderRadius: 4),
                          const SizedBox(height: 8),
                          buildShimmerBox(width: 150, height: 12, borderRadius: 4),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              buildShimmerBox(width: 60, height: 20, borderRadius: 6),
                              const Spacer(),
                              buildShimmerBox(width: 60, height: 24, borderRadius: 12),
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
      }),
    ),
  );
}

Widget buildCircularShimmer({double size = 20}) {
  return Shimmer.fromColors(
    baseColor: Colors.grey.shade300,
    highlightColor: Colors.grey.shade100,
    child: Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    ),
  );
}
