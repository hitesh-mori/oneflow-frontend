class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String userType;
  final String? createdAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      userType: json['userType'] ?? '',
      createdAt: json['createdAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'createdAt': createdAt,
    };
  }
}
