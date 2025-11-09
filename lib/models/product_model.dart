class ProductModel {
  final String id;
  final String name;
  final List<String> type; // ["sale", "purchase"] or just ["sale"] or ["purchase"]
  final String unit;
  final double saleTax;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProductModel({
    required this.id,
    required this.name,
    required this.type,
    required this.unit,
    required this.saleTax,
    this.createdAt,
    this.updatedAt,
  });

  // Factory constructor to create a ProductModel from JSON
  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] != null
          ? List<String>.from(json['type'])
          : [],
      unit: json['unit'] ?? '',
      saleTax: (json['saleTax'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  // Method to convert ProductModel to JSON
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
      'type': type,
      'unit': unit,
      'saleTax': saleTax,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Method to create JSON for API requests (without _id)
  Map<String, dynamic> toCreateJson() {
    return {
      'name': name,
      'type': type,
      'unit': unit,
      'saleTax': saleTax,
    };
  }

  // Copy with method for updates
  ProductModel copyWith({
    String? id,
    String? name,
    List<String>? type,
    String? unit,
    double? saleTax,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      unit: unit ?? this.unit,
      saleTax: saleTax ?? this.saleTax,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper getters
  bool get canBeSold => type.contains('sale');
  bool get canBePurchased => type.contains('purchase');
  String get typeDisplay {
    if (type.length == 2) return 'Sale & Purchase';
    if (type.contains('sale')) return 'Sale';
    if (type.contains('purchase')) return 'Purchase';
    return 'Unknown';
  }

  String get formattedSaleTax => '${saleTax.toStringAsFixed(0)}%';
}
