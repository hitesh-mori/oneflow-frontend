import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';

class StorageService {

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _pageTitleKey = 'page_title';
  static const String _userDataKey = 'user_data';

  // Cache SharedPreferences instance for better performance
  static SharedPreferences? _prefs;

  /// Get SharedPreferences instance (cached)
  static Future<SharedPreferences> _getPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  static Future<void> saveTokens(String accessToken, String refreshToken) async {
    final prefs = await _getPrefs();
    await prefs.setString(_accessTokenKey, accessToken);
    await prefs.setString(_refreshTokenKey, refreshToken);
  }

  static Future<String?> getAccessToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_accessTokenKey);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await _getPrefs();
    return prefs.getString(_refreshTokenKey);
  }

  // Get user type from stored user data
  static Future<String?> getUserType() async {
    final user = await getUserData();
    return user?.userType;
  }

  // Get user email from stored user data
  static Future<String?> getUserEmail() async {
    final user = await getUserData();
    return user?.email;
  }

  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  static Future<void> savePageTitle(String title) async {
    final prefs = await _getPrefs();
    await prefs.setString(_pageTitleKey, title);
  }

  static Future<String?> getPageTitle() async {
    final prefs = await _getPrefs();
    return prefs.getString(_pageTitleKey);
  }

  static Future<void> saveUserData(UserModel user) async {
    if (kDebugMode) {
      debugPrint('💾 StorageService: Saving user data - ${user.name}');
    }
    final prefs = await _getPrefs();
    final userJson = jsonEncode(user.toJson());
    await prefs.setString(_userDataKey, userJson);
    if (kDebugMode) {
      debugPrint('✅ StorageService: User data saved successfully');
    }
  }

  static Future<UserModel?> getUserData() async {
    if (kDebugMode) {
      debugPrint('📖 StorageService: Reading user data...');
    }
    final prefs = await _getPrefs();
    final userJson = prefs.getString(_userDataKey);
    if (kDebugMode) {
      debugPrint('📖 StorageService: userJson = $userJson');
    }
    if (userJson != null) {
      try {
        final userMap = jsonDecode(userJson) as Map<String, dynamic>;
        final user = UserModel.fromJson(userMap);
        if (kDebugMode) {
          debugPrint('✅ StorageService: User data retrieved - ${user.name}');
        }
        return user;
      } catch (e) {
        if (kDebugMode) {
          debugPrint('❌ StorageService: Error parsing user data - $e');
        }
        return null;
      }
    }
    if (kDebugMode) {
      debugPrint('⚠️ StorageService: No user data found');
    }
    return null;
  }

  static Future<void> clearAll() async {
    final prefs = await _getPrefs();
    await prefs.remove(_accessTokenKey);
    await prefs.remove(_refreshTokenKey);
    await prefs.remove(_userDataKey);
  }
}
