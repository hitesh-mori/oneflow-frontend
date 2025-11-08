import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'storage_service.dart';

class ApiService {
  static const String baseUrl = 'http://10.206.32.108:4000';

  static Future<Map<String, String>> _getHeaders({bool needsAuth = false}) async {
    final headers = {
      'Content-Type': 'application/json',
    };

    if (needsAuth) {
      final token = await StorageService.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  static Future<http.Response> get(String endpoint, {bool needsAuth = false}) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final url = '$baseUrl$endpoint';

    if (kDebugMode) {
      debugPrint('🌐 API GET Request:');
      debugPrint('   URL: $url');
      debugPrint('   Headers: $headers');
    }

    try {
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (kDebugMode) {
        debugPrint('📦 API Response:');
        debugPrint('   Status: ${response.statusCode}');
        debugPrint('   Body: ${response.body}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ API Error: $e');
      }
      rethrow;
    }
  }

  static Future<http.Response> post(
    String endpoint,
    Map<String, dynamic> body, {
    bool needsAuth = false,
  }) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final url = '$baseUrl$endpoint';

    if (kDebugMode) {
      debugPrint('🌐 API POST Request:');
      debugPrint('   URL: $url');
      debugPrint('   Headers: $headers');
      debugPrint('   Body: ${jsonEncode(body)}');
    }

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        debugPrint('API Response:');
        debugPrint('Status: ${response.statusCode}');
        debugPrint('Body: ${response.body}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('API Error: $e');
      }
      rethrow;
    }
  }

  static Future<http.Response> put(
    String endpoint,
    Map<String, dynamic> body, {
    bool needsAuth = false,
  }) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );
    return response;
  }

  static Future<http.Response> delete(String endpoint, {bool needsAuth = false}) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );
    return response;
  }

  static Future<http.Response> patch(
    String endpoint,
    Map<String, dynamic> body, {
    bool needsAuth = false,
  }) async {
    final headers = await _getHeaders(needsAuth: needsAuth);
    final url = '$baseUrl$endpoint';

    if (kDebugMode) {
      debugPrint('🌐 API PATCH Request:');
      debugPrint('   URL: $url');
      debugPrint('   Headers: $headers');
      debugPrint('   Body: ${jsonEncode(body)}');
    }

    try {
      final response = await http.patch(
        Uri.parse(url),
        headers: headers,
        body: jsonEncode(body),
      );

      if (kDebugMode) {
        debugPrint('📦 API Response:');
        debugPrint('   Status: ${response.statusCode}');
        debugPrint('   Body: ${response.body}');
      }

      return response;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ API Error: $e');
      }
      rethrow;
    }
  }
}
