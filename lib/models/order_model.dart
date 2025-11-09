import 'package:frontend/models/partner_model.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/models/project_model.dart';

class OrderLineModel {
  final String? id;
  final ProductModel? product;
  final String? productId;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double taxPercent;
  final double amount;

  OrderLineModel({
    this.id,
    this.product,
    this.productId,
    required this.quantity,
    required this.unit,
    required this.unitPrice,
    required this.taxPercent,
    required this.amount,
  });

  factory OrderLineModel.fromJson(Map<String, dynamic> json) {
    return OrderLineModel(
      id: json['_id'],
      product: json['product'] != null && json['product'] is Map
          ? ProductModel.fromJson(json['product'])
          : null,
      productId: json['product'] is String ? json['product'] : null,
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      unitPrice: (json['unitPrice'] ?? 0).toDouble(),
      taxPercent: (json['taxPercent'] ?? 0).toDouble(),
      amount: (json['amount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) '_id': id,
      'product': productId ?? product?.id,
      'quantity': quantity,
      'unit': unit,
      'unitPrice': unitPrice,
      'taxPercent': taxPercent,
      'amount': amount,
    };
  }

  double get taxAmount => amount * (taxPercent / 100);
  double get totalAmount => amount + taxAmount;

  OrderLineModel copyWith({
    String? id,
    ProductModel? product,
    String? productId,
    int? quantity,
    String? unit,
    double? unitPrice,
    double? taxPercent,
    double? amount,
  }) {
    return OrderLineModel(
      id: id ?? this.id,
      product: product ?? this.product,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      taxPercent: taxPercent ?? this.taxPercent,
      amount: amount ?? this.amount,
    );
  }
}

class OrderModel {
  final String id;
  final String code;
  final String type; // "Sales" or "Purchase"
  final PartnerModel? partner;
  final String? partnerId;
  final ProjectModel? project;
  final String? projectId;
  final DateTime orderDate;
  final String status; // Draft, Confirmed, Done, Cancelled
  final List<OrderLineModel> lines;
  final double untaxedAmount;
  final double totalAmount;
  final List<String> relatedInvoices;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  OrderModel({
    required this.id,
    required this.code,
    required this.type,
    this.partner,
    this.partnerId,
    this.project,
    this.projectId,
    required this.orderDate,
    required this.status,
    required this.lines,
    required this.untaxedAmount,
    required this.totalAmount,
    this.relatedInvoices = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      id: json['_id'] ?? json['id'] ?? '',
      code: json['code'] ?? '',
      type: json['type'] ?? 'Sales',
      partner: json['partner'] != null && json['partner'] is Map
          ? PartnerModel.fromJson(json['partner'])
          : json['customer'] != null && json['customer'] is Map
              ? PartnerModel.fromJson(json['customer'])
              : null,
      partnerId: json['partner'] is String ? json['partner'] : null,
      project: json['project'] != null && json['project'] is Map
          ? ProjectModel.fromJson(json['project'])
          : null,
      projectId: json['project'] is String ? json['project'] : null,
      orderDate: json['orderDate'] != null
          ? DateTime.parse(json['orderDate'])
          : DateTime.now(),
      status: json['status'] ?? 'Draft',
      lines: json['lines'] != null
          ? (json['lines'] as List)
              .map((line) => OrderLineModel.fromJson(line))
              .toList()
          : [],
      untaxedAmount: (json['untaxedAmount'] ?? 0).toDouble(),
      totalAmount: (json['totalAmount'] ?? 0).toDouble(),
      relatedInvoices: json['relatedInvoices'] != null
          ? List<String>.from(json['relatedInvoices'])
          : [],
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
      '_id': id,
      'code': code,
      'type': type,
      'partner': partnerId ?? partner?.id,
      'project': projectId ?? project?.id,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'lines': lines.map((line) => line.toJson()).toList(),
      'untaxedAmount': untaxedAmount,
      'totalAmount': totalAmount,
      'relatedInvoices': relatedInvoices,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  Map<String, dynamic> toCreateJson() {
    return {
      'type': type,
      'partner': partnerId ?? partner?.id,
      'project': projectId ?? project?.id,
      'orderDate': orderDate.toIso8601String().split('T')[0],
      'status': status,
      'lines': lines.map((line) => line.toJson()).toList(),
    };
  }

  OrderModel copyWith({
    String? id,
    String? code,
    String? type,
    PartnerModel? partner,
    String? partnerId,
    ProjectModel? project,
    String? projectId,
    DateTime? orderDate,
    String? status,
    List<OrderLineModel>? lines,
    double? untaxedAmount,
    double? totalAmount,
    List<String>? relatedInvoices,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return OrderModel(
      id: id ?? this.id,
      code: code ?? this.code,
      type: type ?? this.type,
      partner: partner ?? this.partner,
      partnerId: partnerId ?? this.partnerId,
      project: project ?? this.project,
      projectId: projectId ?? this.projectId,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      lines: lines ?? this.lines,
      untaxedAmount: untaxedAmount ?? this.untaxedAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      relatedInvoices: relatedInvoices ?? this.relatedInvoices,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isSalesOrder => type.toLowerCase() == 'sales';
  bool get isPurchaseOrder => type.toLowerCase() == 'purchase';
  bool get isDraft => status.toLowerCase() == 'draft';
  bool get isConfirmed => status.toLowerCase() == 'confirmed';
  bool get isDone => status.toLowerCase() == 'done';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get partnerName => partner?.name ?? 'N/A';
  String get projectName => project?.name ?? 'N/A';
  String get statusDisplay => status[0].toUpperCase() + status.substring(1);
}
