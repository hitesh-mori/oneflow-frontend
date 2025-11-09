class PartnerModel {
  final String id;
  final String name;
  final String type; // "Customer" or "Vendor"
  final String email;
  final String phone;
  final String address;
  final String? gstNumber;
  final bool? isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  PartnerModel({
    required this.id,
    required this.name,
    required this.type,
    required this.email,
    required this.phone,
    required this.address,
    this.gstNumber,
    this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a PartnerModel from JSON
  factory PartnerModel.fromJson(Map<String, dynamic> json) {
    return PartnerModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? 'Customer',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      address: json['address'] ?? '',
      gstNumber: json['gstNumber'],
      isActive: json['isActive'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Method to convert PartnerModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'email': email,
      'phone': phone,
      'address': address,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (isActive != null) 'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Method to create JSON for API requests (without _id)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'type': type,
      'email': email,
      'phone': phone,
      'address': address,
      if (gstNumber != null) 'gstNumber': gstNumber,
      if (isActive != null) 'isActive': isActive,
    };
  }

  // Copy with method for updates
  PartnerModel copyWith({
    String? id,
    String? name,
    String? type,
    String? email,
    String? phone,
    String? address,
    String? gstNumber,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PartnerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      gstNumber: gstNumber ?? this.gstNumber,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get isCustomer => type.toLowerCase() == 'customer';
  bool get isVendor => type.toLowerCase() == 'vendor';
  String get displayType => type[0].toUpperCase() + type.substring(1).toLowerCase();
}
