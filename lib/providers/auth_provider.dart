import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

class AuthProvider with ChangeNotifier {
  UserModel? _user;
  bool _isLoading = false;
  bool _isAuthenticated = false;

  UserModel? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _isAuthenticated;

  Future<void> checkAuthStatus() async {
    if (kDebugMode) {
      debugPrint('🔍 checkAuthStatus: Starting...');
    }
    _isLoading = true;
    notifyListeners();

    final isLoggedIn = await StorageService.isLoggedIn();
    if (kDebugMode) {
      debugPrint('🔍 checkAuthStatus: isLoggedIn = $isLoggedIn');
    }

    if (isLoggedIn) {
      // First, load user data from local storage for instant display
      final cachedUser = await StorageService.getUserData();
      if (kDebugMode) {
        debugPrint('🔍 checkAuthStatus: cachedUser = ${cachedUser?.name}');
      }

      if (cachedUser != null) {
        _user = cachedUser;
        _isAuthenticated = true;
        _isLoading = false;
        if (kDebugMode) {
          debugPrint('✅ checkAuthStatus: Loaded cached user - ${cachedUser.name}');
        }
        notifyListeners();
      }

      // Then, fetch fresh data from API in the background
      if (kDebugMode) {
        debugPrint('🔍 checkAuthStatus: Fetching fresh profile from API...');
      }
      final user = await AuthService.getProfile();
      if (kDebugMode) {
        debugPrint('🔍 checkAuthStatus: API user = ${user?.name}');
      }

      if (user != null) {
        // Only update if we got valid data from API
        if (user.name.isNotEmpty && user.email.isNotEmpty) {
          _user = user;
          _isAuthenticated = true;
          if (kDebugMode) {
            debugPrint('✅ checkAuthStatus: Loaded API user - ${user.name}');
          }
          notifyListeners();
        } else {
          if (kDebugMode) {
            debugPrint('⚠️ checkAuthStatus: API returned invalid user data, keeping cached data');
          }
        }
      } else {
        if (kDebugMode) {
          debugPrint('⚠️ checkAuthStatus: API call failed, cachedUser = $cachedUser');
        }
        // Only clear if we didn't have cached data
        if (cachedUser == null) {
          _isAuthenticated = false;
          await StorageService.clearAll();
          if (kDebugMode) {
            debugPrint('❌ checkAuthStatus: Cleared all data');
          }
        } else {
          if (kDebugMode) {
            debugPrint('✅ checkAuthStatus: Keeping cached data since API failed');
          }
        }
      }
    } else {
      _isAuthenticated = false;
      if (kDebugMode) {
        debugPrint('❌ checkAuthStatus: User not logged in');
      }
    }

    _isLoading = false;
    notifyListeners();
    if (kDebugMode) {
      debugPrint('✅ checkAuthStatus: Complete - user = ${_user?.name}');
    }
  }

  Future<bool> signIn(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final response = await AuthService.signIn(email: email, password: password);

    if (response.success && response.data?.user != null) {
      _user = response.data!.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String userType,
  }) async {
    _isLoading = true;
    notifyListeners();

    final response = await AuthService.signUp(
      name: name,
      email: email,
      password: password,
      phone: phone,
      userType: userType,
    );

    if (response.success && response.data?.user != null) {
      _user = response.data!.user;
      _isAuthenticated = true;
      _isLoading = false;
      notifyListeners();
      return true;
    } else {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    notifyListeners();

    await AuthService.logout();
    _user = null;
    _isAuthenticated = false;

    _isLoading = false;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    final user = await AuthService.getProfile();
    if (user != null) {
      _user = user;
      notifyListeners();
    }
  }
}
