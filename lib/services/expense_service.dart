import 'dart:convert';
import '../models/expense_model.dart';
import 'api_service.dart';

class ExpenseService {
  /// Create a new expense
  static Future<ExpenseModel?> createExpense(Map<String, dynamic> expenseData) async {
    try {
      print('💰 ExpenseService: Creating expense');
      final response = await ApiService.post(
        '/api/expense',
        expenseData,
        needsAuth: true,
      );

      print('📦 ExpenseService: Create response: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return ExpenseModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ ExpenseService.createExpense: Error - $e');
      rethrow;
    }
  }

  /// Get all expenses for current user
  static Future<List<ExpenseModel>> getMyExpenses({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      print('💰 ExpenseService: Fetching my expenses');
      final queryParams = '?my=true&page=$page&limit=$limit';
      final response = await ApiService.get(
        '/api/expense$queryParams',
        needsAuth: true,
      );

      print('📦 ExpenseService: Get expenses response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> expensesData = data['data'] ?? [];
          return expensesData.map((e) => ExpenseModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ ExpenseService.getMyExpenses: Error - $e');
      rethrow;
    }
  }

  /// Get all expenses (Admin only)
  static Future<List<ExpenseModel>> getAllExpenses({
    int page = 1,
    int limit = 100,
  }) async {
    try {
      print('💰 ExpenseService: Fetching all expenses');
      final queryParams = '?page=$page&limit=$limit';
      final response = await ApiService.get(
        '/api/expense$queryParams',
        needsAuth: true,
      );

      print('📦 ExpenseService: Get all expenses response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> expensesData = data['data'] ?? [];
          return expensesData.map((e) => ExpenseModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ ExpenseService.getAllExpenses: Error - $e');
      rethrow;
    }
  }

  /// Get expenses for a specific project
  static Future<List<ExpenseModel>> getProjectExpenses(String projectId) async {
    try {
      print('💰 ExpenseService: Fetching expenses for project $projectId');
      final response = await ApiService.get(
        '/api/expense/project/$projectId',
        needsAuth: true,
      );

      print('📦 ExpenseService: Get project expenses response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          final List<dynamic> expensesData = data['data'] ?? [];
          return expensesData.map((e) => ExpenseModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ ExpenseService.getProjectExpenses: Error - $e');
      rethrow;
    }
  }

  /// Delete an expense
  static Future<bool> deleteExpense(String expenseId) async {
    try {
      print('💰 ExpenseService: Deleting expense $expenseId');
      final response = await ApiService.delete(
        '/api/expense/$expenseId',
        needsAuth: true,
      );

      print('📦 ExpenseService: Delete response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['success'] ?? false;
      }
      return false;
    } catch (e) {
      print('❌ ExpenseService.deleteExpense: Error - $e');
      rethrow;
    }
  }

  /// Update an expense
  static Future<ExpenseModel?> updateExpense(
    String expenseId,
    Map<String, dynamic> updateData,
  ) async {
    try {
      print('💰 ExpenseService: Updating expense $expenseId');
      final response = await ApiService.put(
        '/api/expense/$expenseId',
        updateData,
        needsAuth: true,
      );

      print('📦 ExpenseService: Update response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return ExpenseModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ ExpenseService.updateExpense: Error - $e');
      rethrow;
    }
  }

  /// Update expense status (Approve/Reject)
  static Future<ExpenseModel?> updateExpenseStatus(
    String expenseId,
    String status,
  ) async {
    try {
      print('💰 ExpenseService: Updating expense status $expenseId to $status');
      final response = await ApiService.patch(
        '/api/expense/$expenseId/status',
        {'status': status},
        needsAuth: true,
      );

      print('📦 ExpenseService: Update status response: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success']) {
          return ExpenseModel.fromJson(data['data']);
        }
      }
      return null;
    } catch (e) {
      print('❌ ExpenseService.updateExpenseStatus: Error - $e');
      rethrow;
    }
  }
}
