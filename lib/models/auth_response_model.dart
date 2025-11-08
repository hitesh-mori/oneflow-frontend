import 'user_model.dart';

class AuthResponseModel {
  final bool success;
  final String message;
  final AuthData? data;
  final String? error;

  AuthResponseModel({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] != null ? AuthData.fromJson(json['data']) : null,
      error: json['error'],
    );
  }
}

class AuthData {
  final UserModel? user;
  final String? accessToken;
  final String? refreshToken;

  AuthData({
    this.user,
    this.accessToken,
    this.refreshToken,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) {
    return AuthData(
      user: json['user'] != null ? UserModel.fromJson(json['user']) : null,
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
    );
  }
}
