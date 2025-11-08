import 'dart:convert';
import '../models/task_model.dart';
import 'api_service.dart';

class TaskService {
  /// Create a new task
  static Future<TaskModel?> createTask(Map<String, dynamic> taskData) async {
    try {
      final response = await ApiService.post(
        '/api/task',
        taskData,
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ TaskService.createTask: Error - $e');
      rethrow;
    }
  }

  /// Get all tasks for a project
  static Future<Map<String, dynamic>> getTasksForProject(
    String projectId, {
    bool myTasks = false,
    int page = 1,
    int limit = 20,
    String? state,
    String? priority,
  }) async {
    try {
      final queryParams = <String, String>{
        'my': myTasks.toString(),
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (state != null) queryParams['state'] = state;
      if (priority != null) queryParams['priority'] = priority;

      final uri = Uri(
        path: '/api/task/project/$projectId',
        queryParameters: queryParams,
      );

      final response = await ApiService.get(uri.toString(), needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final tasksData = data['data'];
          final List<dynamic> tasksList = tasksData['tasks'] ?? [];
          final tasks = tasksList.map((t) => TaskModel.fromJson(t)).toList();
          final total = tasksData['total'] ?? 0;

          return {
            'tasks': tasks,
            'total': total,
          };
        }
      }
      return {'tasks': <TaskModel>[], 'total': 0};
    } catch (e) {
      print('❌ TaskService.getTasksForProject: Error - $e');
      rethrow;
    }
  }

  /// Update a task
  static Future<TaskModel?> updateTask(String taskId, Map<String, dynamic> updateData) async {
    try {
      final response = await ApiService.put(
        '/api/task/$taskId',
        updateData,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ TaskService.updateTask: Error - $e');
      rethrow;
    }
  }

  /// Delete a task
  static Future<bool> deleteTask(String taskId) async {
    try {
      final response = await ApiService.delete('/api/task/$taskId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ TaskService.deleteTask: Error - $e');
      rethrow;
    }
  }

  /// Update task state (new, in_progress, blocked, done)
  static Future<TaskModel?> updateTaskState(String taskId, String state) async {
    try {
      final response = await ApiService.patch(
        '/api/task/$taskId/state',
        {'state': state},
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ TaskService.updateTaskState: Error - $e');
      rethrow;
    }
  }

  /// Assign users to a task
  static Future<TaskModel?> assignUsersToTask(String taskId, List<String> userIds) async {
    try {
      final response = await ApiService.put(
        '/api/task/$taskId',
        {'assignees': userIds},
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ TaskService.assignUsersToTask: Error - $e');
      rethrow;
    }
  }

  /// Add a comment to a task
  static Future<TaskModel?> addComment(String taskId, String text) async {
    try {
      final response = await ApiService.post(
        '/api/task/$taskId/comment',
        {'text': text},
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ TaskService.addComment: Error - $e');
      rethrow;
    }
  }

  /// Log time to a task
  static Future<TaskModel?> logTime(
    String taskId, {
    required double hours,
    required DateTime date,
    bool billable = true,
    String? note,
  }) async {
    try {
      print('🕒 TaskService: Logging time for task $taskId');
      final response = await ApiService.post(
        '/api/task/$taskId/time-logs',
        {
          'hours': hours,
          'date': date.toIso8601String(),
          'billable': billable,
          if (note != null) 'note': note,
        },
        needsAuth: true,
      );

      print('📦 TaskService: Log time response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return TaskModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ TaskService.logTime: Error - $e');
      rethrow;
    }
  }

  /// Get time logs for a task
  static Future<List<TimeLogModel>> getTimeLogs(String taskId, {bool myLogs = false}) async {
    try {
      print('🕒 TaskService: Fetching time logs for task $taskId');
      final queryParams = myLogs ? '?my=true' : '';
      final response = await ApiService.get(
        '/api/task/$taskId/time-logs$queryParams',
        needsAuth: true,
      );

      print('📦 TaskService: Get time logs response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          // Backend returns: { success: true, data: { logs: [...], total, page, limit } }
          final responseData = data['data'];
          if (responseData is Map && responseData.containsKey('logs')) {
            final List<dynamic> logsData = responseData['logs'] ?? [];
            return logsData.map((log) => TimeLogModel.fromJson(log)).toList();
          } else if (responseData is List) {
            // Fallback: if backend returns array directly
            return responseData.map((log) => TimeLogModel.fromJson(log)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      print('❌ TaskService.getTimeLogs: Error - $e');
      rethrow;
    }
  }

  /// Delete a time log
  static Future<bool> deleteTimeLog(String taskId, String logId) async {
    try {
      print('🕒 TaskService: Deleting time log $logId from task $taskId');
      final response = await ApiService.delete(
        '/api/task/$taskId/time-logs/$logId',
        needsAuth: true,
      );

      print('📦 TaskService: Delete time log response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ TaskService.deleteTimeLog: Error - $e');
      rethrow;
    }
  }
}
