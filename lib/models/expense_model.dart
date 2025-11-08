class ExpenseSubmitter {
  final String id;
  final String name;
  final String email;
  final String? userType;

  ExpenseSubmitter({
    required this.id,
    required this.name,
    required this.email,
    this.userType,
  });

  factory ExpenseSubmitter.fromJson(Map<String, dynamic> json) {
    return ExpenseSubmitter(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      userType: json['userType'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'userType': userType,
    };
  }

  String get roleLabel {
    switch (userType) {
      case 'project_manager':
        return 'Project Manager';
      case 'team_member':
        return 'Team Member';
      case 'sales':
        return 'Sales';
      case 'admin':
        return 'Admin';
      default:
        return userType ?? 'User';
    }
  }
}

class ExpenseProject {
  final String id;
  final String name;

  ExpenseProject({
    required this.id,
    required this.name,
  });

  factory ExpenseProject.fromJson(Map<String, dynamic> json) {
    return ExpenseProject(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
    };
  }
}

class ExpenseModel {
  final String id;
  final String name;
  final String expensePeriod;
  final String project; // Can be ID or populated project
  final ExpenseProject? projectDetails; // Populated project data
  final ExpenseSubmitter? submittedBy;
  final String description;
  final double amount;
  final bool billable;
  final String status; // 'Draft', 'Submitted', 'Approved', 'Reimbursed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExpenseModel({
    required this.id,
    required this.name,
    required this.expensePeriod,
    required this.project,
    this.projectDetails,
    this.submittedBy,
    required this.description,
    required this.amount,
    this.billable = false,
    this.status = 'Draft',
    this.createdAt,
    this.updatedAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    // Handle project field - can be string ID or populated object
    String projectId;
    ExpenseProject? projectDetails;

    if (json['project'] is String) {
      projectId = json['project'];
    } else if (json['project'] is Map) {
      final projectMap = json['project'] as Map<String, dynamic>;
      projectId = projectMap['_id'] ?? projectMap['id'] ?? '';
      projectDetails = ExpenseProject.fromJson(projectMap);
    } else {
      projectId = '';
    }

    return ExpenseModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      expensePeriod: json['expensePeriod'] ?? '',
      project: projectId,
      projectDetails: projectDetails,
      submittedBy: json['submittedBy'] != null
          ? ExpenseSubmitter.fromJson(json['submittedBy'])
          : null,
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      billable: json['billable'] ?? false,
      status: json['status'] ?? 'Draft',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'expensePeriod': expensePeriod,
      'project': project,
      'description': description,
      'amount': amount,
      'billable': billable,
      'status': status,
    };
  }

  ExpenseModel copyWith({
    String? id,
    String? name,
    String? expensePeriod,
    String? project,
    ExpenseProject? projectDetails,
    ExpenseSubmitter? submittedBy,
    String? description,
    double? amount,
    bool? billable,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      name: name ?? this.name,
      expensePeriod: expensePeriod ?? this.expensePeriod,
      project: project ?? this.project,
      projectDetails: projectDetails ?? this.projectDetails,
      submittedBy: submittedBy ?? this.submittedBy,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      billable: billable ?? this.billable,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get projectName => projectDetails?.name ?? '';
  String get submitterName => submittedBy?.name ?? '';
}

// Expense Status Constants
class ExpenseStatus {
  static const String submitted = 'Submitted';
  static const String approved = 'Approved';
  static const String rejected = 'Rejected';
  static const String rejectedByAdmin = 'RejectedByAdmin';
  static const String reimbursed = 'Reimbursed';

  static const List<String> allStatuses = [
    submitted,
    approved,
    rejected,
    rejectedByAdmin,
    reimbursed,
  ];

  static String getLabel(String status) {
    switch (status) {
      case submitted:
        return 'Submitted';
      case approved:
        return 'Approved';
      case rejected:
        return 'Rejected';
      case rejectedByAdmin:
        return 'Rejected by Admin';
      case reimbursed:
        return 'Reimbursed';
      default:
        return status;
    }
  }
}
