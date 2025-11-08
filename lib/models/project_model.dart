class LinkModel {
  final String type; // 'sales_order', 'purchase_order', 'customer_invoice', 'vendor_bill', 'expense', 'other'
  final String? externalId;
  final String? url;

  LinkModel({
    required this.type,
    this.externalId,
    this.url,
  });

  factory LinkModel.fromJson(Map<String, dynamic> json) {
    return LinkModel(
      type: json['type'] ?? 'other',
      externalId: json['externalId'],
      url: json['url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (externalId != null) 'externalId': externalId,
      if (url != null) 'url': url,
    };
  }
}

class ProjectMemberModel {
  final String id;
  final String name;
  final String email;

  ProjectMemberModel({
    required this.id,
    required this.name,
    required this.email,
  });

  factory ProjectMemberModel.fromJson(Map<String, dynamic> json) {
    return ProjectMemberModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
    };
  }
}

class ProjectModel {
  final String id;
  final String name;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budget;
  final double costToDate;
  final ProjectMemberModel? manager;
  final List<ProjectMemberModel> members;
  final String status; // 'planned', 'active', 'on_hold', 'completed', 'cancelled'
  final Map<String, dynamic>? metadata;
  final List<LinkModel> links;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel({
    required this.id,
    required this.name,
    this.description,
    this.startDate,
    this.endDate,
    this.budget = 0,
    this.costToDate = 0,
    this.manager,
    this.members = const [],
    this.status = 'planned',
    this.metadata,
    this.links = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      budget: (json['budget'] ?? 0).toDouble(),
      costToDate: (json['costToDate'] ?? 0).toDouble(),
      manager: json['manager'] != null && json['manager'] is Map<String, dynamic>
          ? ProjectMemberModel.fromJson(json['manager'] as Map<String, dynamic>)
          : null,
      members: json['members'] != null
          ? (json['members'] as List)
              .where((m) => m is Map<String, dynamic>)
              .map((m) => ProjectMemberModel.fromJson(m as Map<String, dynamic>))
              .toList()
          : [],
      status: json['status'] ?? 'planned',
      metadata: json['metadata'],
      links: json['links'] != null
          ? (json['links'] as List).map((l) => LinkModel.fromJson(l)).toList()
          : [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (description != null) 'description': description,
      if (startDate != null) 'startDate': startDate!.toIso8601String(),
      if (endDate != null) 'endDate': endDate!.toIso8601String(),
      'budget': budget,
      'costToDate': costToDate,
      if (manager != null) 'manager': manager!.id,
      'members': members.map((m) => m.id).toList(),
      'status': status,
      if (metadata != null) 'metadata': metadata,
      'links': links.map((l) => l.toJson()).toList(),
    };
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? budget,
    double? costToDate,
    ProjectMemberModel? manager,
    List<ProjectMemberModel>? members,
    String? status,
    Map<String, dynamic>? metadata,
    List<LinkModel>? links,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      budget: budget ?? this.budget,
      costToDate: costToDate ?? this.costToDate,
      manager: manager ?? this.manager,
      members: members ?? this.members,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
      links: links ?? this.links,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  double get remainingBudget => budget - costToDate;

  int get daysRemaining {
    if (endDate == null) return 0;
    final now = DateTime.now();
    final difference = endDate!.difference(now);
    return difference.inDays;
  }

  bool get isOverBudget => costToDate > budget;

  bool get isOverdue {
    if (endDate == null) return false;
    return DateTime.now().isAfter(endDate!) && status != 'completed';
  }
}

// Project Status Constants
class ProjectStatus {
  static const String planned = 'planned';
  static const String active = 'active';
  static const String onHold = 'on_hold';
  static const String completed = 'completed';
  static const String cancelled = 'cancelled';

  static const List<String> allStatuses = [
    planned,
    active,
    onHold,
    completed,
    cancelled,
  ];

  static String getLabel(String status) {
    switch (status) {
      case planned:
        return 'Planned';
      case active:
        return 'Active';
      case onHold:
        return 'On Hold';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      default:
        return status;
    }
  }
}

// Link Type Constants
class LinkType {
  static const String salesOrder = 'sales_order';
  static const String purchaseOrder = 'purchase_order';
  static const String customerInvoice = 'customer_invoice';
  static const String vendorBill = 'vendor_bill';
  static const String expense = 'expense';
  static const String other = 'other';

  static const List<String> allTypes = [
    salesOrder,
    purchaseOrder,
    customerInvoice,
    vendorBill,
    expense,
    other,
  ];

  static String getLabel(String type) {
    switch (type) {
      case salesOrder:
        return 'Sales Order';
      case purchaseOrder:
        return 'Purchase Order';
      case customerInvoice:
        return 'Customer Invoice';
      case vendorBill:
        return 'Vendor Bill';
      case expense:
        return 'Expense';
      case other:
        return 'Other';
      default:
        return type;
    }
  }
}
