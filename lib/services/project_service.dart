import 'dart:convert';
import '../models/project_model.dart';
import 'api_service.dart';

class ProjectService {
  /// Create a new project
  static Future<ProjectModel?> createProject(Map<String, dynamic> projectData) async {
    try {
      final response = await ApiService.post(
        '/api/project',
        projectData,
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return ProjectModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ ProjectService.createProject: Error - $e');
      rethrow;
    }
  }

  /// Get all projects (admin only)
  static Future<List<ProjectModel>> getAllProjects() async {
    try {
      print('🌐 Fetching all projects...');
      final response = await ApiService.get('/api/project', needsAuth: true);

      print('📦 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Decoded data: $data');

        if (data['success'] == true) {
          final List<dynamic> projectsData = data['data'] ?? [];
          print('✅ Found ${projectsData.length} projects');

          final projects = projectsData.map((p) {
            try {
              return ProjectModel.fromJson(p);
            } catch (e) {
              print('❌ Error parsing project: $e');
              print('❌ Project data: $p');
              rethrow;
            }
          }).toList();

          print('✅ Successfully parsed ${projects.length} projects');
          return projects;
        } else {
          print('❌ API returned success: false');
        }
      } else {
        print('❌ Bad status code: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ ProjectService.getAllProjects: Error - $e');
      rethrow;
    }
  }

  /// Get projects for current manager
  static Future<List<ProjectModel>> getManagerProjects(String managerId) async {
    try {
      print('🌐 Fetching projects for manager: $managerId');
      final response = await ApiService.get('/api/project/manager/$managerId', needsAuth: true);

      print('📦 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Decoded data: $data');

        if (data['success'] == true) {
          final List<dynamic> projectsData = data['data'] ?? [];
          print('✅ Found ${projectsData.length} manager projects');

          final projects = projectsData.map((p) {
            try {
              return ProjectModel.fromJson(p);
            } catch (e) {
              print('❌ Error parsing project: $e');
              print('❌ Project data: $p');
              rethrow;
            }
          }).toList();

          print('✅ Successfully parsed ${projects.length} manager projects');
          return projects;
        } else {
          print('❌ API returned success: false');
        }
      } else {
        print('❌ Bad status code: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ ProjectService.getManagerProjects: Error - $e');
      rethrow;
    }
  }

  /// Get projects for team member (projects where user is a member)
  static Future<List<ProjectModel>> getTeamMemberProjects(String memberId) async {
    try {
      print('🌐 Fetching projects for team member: $memberId');
      final response = await ApiService.get('/api/project/team_member/$memberId', needsAuth: true);

      print('📦 Response Status: ${response.statusCode}');
      print('📦 Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Decoded data: $data');

        if (data['success'] == true) {
          final List<dynamic> projectsData = data['data'] ?? [];
          print('✅ Found ${projectsData.length} team member projects');

          final projects = projectsData.map((p) {
            try {
              return ProjectModel.fromJson(p);
            } catch (e) {
              print('❌ Error parsing project: $e');
              print('❌ Project data: $p');
              rethrow;
            }
          }).toList();

          print('✅ Successfully parsed ${projects.length} team member projects');
          return projects;
        } else {
          print('❌ API returned success: false');
        }
      } else {
        print('❌ Bad status code: ${response.statusCode}');
      }
      return [];
    } catch (e) {
      print('❌ ProjectService.getTeamMemberProjects: Error - $e');
      rethrow;
    }
  }

  /// Get a single project by ID
  static Future<ProjectModel?> getProjectById(String projectId) async {
    try {
      final response = await ApiService.get('/api/project/$projectId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return ProjectModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ ProjectService.getProjectById: Error - $e');
      rethrow;
    }
  }

  /// Update a project
  static Future<ProjectModel?> updateProject(String projectId, Map<String, dynamic> updateData) async {
    try {
      print('🔄 ProjectService: Updating project $projectId');
      print('🔄 ProjectService: Update data: $updateData');

      // Send all data including status in one request
      final response = await ApiService.put(
        '/api/project/$projectId',
        updateData,
        needsAuth: true,
      );

      print('📦 ProjectService: Response status: ${response.statusCode}');
      print('📦 ProjectService: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ ProjectService: Decoded response: $data');

        if (data['success']) {
          print('✅ ProjectService: Parsing project from: ${data['data']}');
          try {
            final project = ProjectModel.fromJson(data['data']);
            print('✅ ProjectService: Successfully updated project');
            return project;
          } catch (parseError) {
            print('❌ ProjectService: Parse error: $parseError');
            print('❌ ProjectService: Data that failed to parse: ${data['data']}');
            rethrow;
          }
        }
      }
      return null;
    } catch (e) {
      print('❌ ProjectService.updateProject: Error - $e');
      rethrow;
    }
  }

  /// Delete a project
  static Future<bool> deleteProject(String projectId) async {
    try {
      final response = await ApiService.delete('/api/project/$projectId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ ProjectService.deleteProject: Error - $e');
      rethrow;
    }
  }

  /// Update project status (active, completed, etc.)
  static Future<ProjectModel?> updateProjectStatus(String projectId, String status) async {
    try {
      print('🔄 ProjectService: Updating project status to: $status');
      final response = await ApiService.patch(
        '/api/project/$projectId/status',
        {'status': status},
        needsAuth: true,
      );

      print('📦 ProjectService: Status update response: ${response.statusCode}');
      print('📦 ProjectService: Status update body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return ProjectModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ ProjectService.updateProjectStatus: Error - $e');
      rethrow;
    }
  }
}
