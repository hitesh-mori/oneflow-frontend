class UserModel {
  final String? id;
  final String name;
  final String email;
  final String? phone;
  final String userType;
  final String? profilePicture;
  final bool isActive;
  final DateTime? lastLogin;
  final double hourlyRate;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.userType,
    this.profilePicture,
    this.isActive = true,
    this.lastLogin,
    this.hourlyRate = 0.0,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      userType: json['userType'] ?? 'guest',
      profilePicture: json['profilePicture'],
      isActive: json['isActive'] ?? true,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'])
          : null,
      hourlyRate: (json['hourlyRate'] ?? 0.0).toDouble(),
      createdAt: json['createdAt'],
      updatedAt: json['updatedAt'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'userType': userType,
      'profilePicture': profilePicture,
      'isActive': isActive,
      'lastLogin': lastLogin?.toIso8601String(),
      'hourlyRate': hourlyRate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  // Helper method to create a copy with modified fields
  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? userType,
    String? profilePicture,
    bool? isActive,
    DateTime? lastLogin,
    double? hourlyRate,
    String? createdAt,
    String? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      profilePicture: profilePicture ?? this.profilePicture,
      isActive: isActive ?? this.isActive,
      lastLogin: lastLogin ?? this.lastLogin,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

// User Type Constants
class UserTypes {
  static const String projectManager = 'project_manager';
  static const String teamMember = 'team_member';
  static const String salesDep = 'sales';
  static const String admin = 'admin';
  static const String guest = 'guest';

  static List<String> get allTypes => [
    projectManager,
    teamMember,
    salesDep,
    admin,
    guest,
  ];

  static String getLabel(String userType) {
    switch (userType) {
      case projectManager:
        return 'Project Manager';
      case teamMember:
        return 'Team Member';
      case salesDep:
        return 'Sales Department';
      case admin:
        return 'Admin';
      case guest:
        return 'Guest';
      default:
        return 'Unknown';
    }
  }
}
