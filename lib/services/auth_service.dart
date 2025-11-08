import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  static Future<AuthResponseModel> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 Sending signup request to API...');
        debugPrint('📧 Email: $email');
        debugPrint('👤 Name: $name');
        debugPrint('🏷️ User Type: $userType');
      }

      final response = await ApiService.post('/api/auth/signup', {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'userType': userType,
      });

      if (kDebugMode) {
        debugPrint('✅ Response received - Status: ${response.statusCode}');
        debugPrint('📦 Response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final authResponse = AuthResponseModel.fromJson(data);
        if (authResponse.data?.accessToken != null && authResponse.data?.refreshToken != null) {
          await StorageService.saveTokens(
            authResponse.data!.accessToken!,
            authResponse.data!.refreshToken!,
          );
          if (authResponse.data?.user != null) {
            await StorageService.saveUserData(authResponse.data!.user!);
          }
        }
        return authResponse;
      } else {
        return AuthResponseModel(
          success: false,
          message: data['message'] ?? 'Signup failed',
          error: data['error'],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Signup error: $e');
      }
      return AuthResponseModel(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  static Future<AuthResponseModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      if (kDebugMode) {
        debugPrint('🚀 Sending signin request to API...');
        debugPrint('📧 Email: $email');
      }

      final response = await ApiService.post('/api/auth/signin', {
        'email': email,
        'password': password,
      });

      if (kDebugMode) {
        debugPrint('✅ Response received - Status: ${response.statusCode}');
        debugPrint('📦 Response body: ${response.body}');
      }

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final authResponse = AuthResponseModel.fromJson(data);
        if (authResponse.data?.accessToken != null && authResponse.data?.refreshToken != null) {
          await StorageService.saveTokens(
            authResponse.data!.accessToken!,
            authResponse.data!.refreshToken!,
          );
          if (authResponse.data?.user != null) {
            await StorageService.saveUserData(authResponse.data!.user!);
          }
        }
        return authResponse;
      } else {
        return AuthResponseModel(
          success: false,
          message: data['message'] ?? 'Login failed',
          error: data['error'],
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Signin error: $e');
      }
      return AuthResponseModel(
        success: false,
        message: 'Network error: ${e.toString()}',
        error: e.toString(),
      );
    }
  }

  static Future<UserModel?> getProfile() async {
    try {
      if (kDebugMode) {
        debugPrint('🌐 AuthService.getProfile: Calling API...');
      }
      final response = await ApiService.get('/api/auth/profile', needsAuth: true);
      if (kDebugMode) {
        debugPrint('🌐 AuthService.getProfile: Status ${response.statusCode}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (kDebugMode) {
          debugPrint('🌐 AuthService.getProfile: Response data = $data');
        }

        if (data['success'] == true && data['data'] != null) {
          final user = UserModel.fromJson(data['data']);
          if (kDebugMode) {
            debugPrint('🌐 AuthService.getProfile: Parsed user = ${user.toJson()}');
          }

          // Only save if we got valid user data
          if (user.name.isNotEmpty && user.email.isNotEmpty) {
            await StorageService.saveUserData(user);
            if (kDebugMode) {
              debugPrint('✅ AuthService.getProfile: Valid user data saved');
            }
            return user;
          } else {
            if (kDebugMode) {
              debugPrint('⚠️ AuthService.getProfile: Invalid user data, not saving');
            }
            return null;
          }
        }
      } else if (response.statusCode == 401) {
        if (kDebugMode) {
          debugPrint('🔑 AuthService.getProfile: Token expired, refreshing...');
        }
        await _refreshToken();
        return await getProfile();
      }
      if (kDebugMode) {
        debugPrint('❌ AuthService.getProfile: Failed to get profile');
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ AuthService.getProfile: Error - $e');
      }
      return null;
    }
  }

  static Future<bool> _refreshToken() async {
    try {
      final refreshToken = await StorageService.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await ApiService.post('/api/auth/refresh', {
        'refreshToken': refreshToken,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          await StorageService.saveTokens(
            data['data']['accessToken'],
            data['data']['refreshToken'],
          );
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> logout() async {
    try {
      await ApiService.post('/api/auth/logout', {}, needsAuth: true);
      await StorageService.clearAll();
      return true;
    } catch (e) {
      await StorageService.clearAll();
      return true;
    }
  }
}
