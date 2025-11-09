import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/models/partner_model.dart';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/models/project_model.dart';
import 'package:frontend/services/order_service.dart';
import 'package:frontend/services/partner_service.dart';
import 'package:frontend/services/product_service.dart';
import 'package:frontend/services/project_service.dart';
import 'package:frontend/services/toast_service.dart';
import 'package:frontend/widgets/custom_button.dart';
import 'package:intl/intl.dart';

class AddEditPurchaseOrderDialog extends StatefulWidget {
  final OrderModel? order;

  const AddEditPurchaseOrderDialog({super.key, this.order});

  @override
  State<AddEditPurchaseOrderDialog> createState() => _AddEditPurchaseOrderDialogState();
}

class _AddEditPurchaseOrderDialogState extends State<AddEditPurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final OrderService _orderService = OrderService();
  final PartnerService _partnerService = PartnerService();
  final ProductService _productService = ProductService();

  List<PartnerModel> _vendors = [];
  List<ProjectModel> _projects = [];
  List<ProductModel> _products = [];

  PartnerModel? _selectedVendor;
  ProjectModel? _selectedProject;
  String _status = 'Draft';
  DateTime _orderDate = DateTime.now();
  List<OrderLineItem> _orderLines = [];

  bool _isLoading = false;
  bool _isLoadingData = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    if (widget.order != null) {
      _initializeFromOrder();
    } else {
      // Add one empty line by default
      _orderLines.add(OrderLineItem());
    }
  }

  void _initializeFromOrder() {
    final order = widget.order!;
    _selectedVendor = order.partner;
    _selectedProject = order.project;
    _status = order.status;
    _orderDate = order.orderDate;

    _orderLines = order.lines.map((line) {
      return OrderLineItem(
        id: line.id,
        product: line.product,
        productId: line.productId,
        quantity: line.quantity,
        unit: line.unit,
        unitPrice: line.unitPrice,
        taxPercent: line.taxPercent,
      );
    }).toList();

    if (_orderLines.isEmpty) {
      _orderLines.add(OrderLineItem());
    }
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoadingData = true);
    await Future.wait([
      _loadVendors(),
      _loadProjects(),
      _loadProducts(),
    ]);
    setState(() => _isLoadingData = false);
  }

  Future<void> _loadVendors() async {
    final result = await _partnerService.getPartnersByType('Vendor');
    if (result['success']) {
      setState(() {
        _vendors = result['data'];
      });
    }
  }

  Future<void> _loadProjects() async {
    try {
      final projects = await ProjectService.getAllProjects();
      setState(() {
        _projects = projects;
      });
    } catch (e) {
      print('Error loading projects: $e');
    }
  }

  Future<void> _loadProducts() async {
    final result = await _productService.getProductsByType('purchase');
    if (result['success']) {
      setState(() {
        _products = result['data'];
      });
    }
  }

  void _addOrderLine() {
    setState(() {
      _orderLines.add(OrderLineItem());
    });
  }

  void _removeOrderLine(int index) {
    if (_orderLines.length > 1) {
      setState(() {
        _orderLines.removeAt(index);
      });
    } else {
      AppToast.showError(context, 'At least one order line is required');
    }
  }

  void _updateOrderLine(int index, OrderLineItem updatedLine) {
    setState(() {
      _orderLines[index] = updatedLine;
    });
  }

  double get _untaxedAmount {
    return _orderLines.fold(0.0, (sum, line) => sum + line.amount);
  }

  double get _totalAmount {
    return _orderLines.fold(0.0, (sum, line) => sum + line.totalAmount);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedVendor == null) {
      AppToast.showError(context, 'Please select a vendor');
      return;
    }

    if (_selectedProject == null) {
      AppToast.showError(context, 'Please select a project');
      return;
    }

    // Validate that all order lines have products selected
    for (int i = 0; i < _orderLines.length; i++) {
      if (_orderLines[i].product == null) {
        AppToast.showError(context, 'Please select a product for line ${i + 1}');
        return;
      }
      if (_orderLines[i].quantity <= 0) {
        AppToast.showError(context, 'Please enter a valid quantity for line ${i + 1}');
        return;
      }
      if (_orderLines[i].unitPrice <= 0) {
        AppToast.showError(context, 'Please enter a valid unit price for line ${i + 1}');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final orderData = OrderModel(
        id: widget.order?.id ?? '',
        code: widget.order?.code ?? 'New Purchase Order',
        type: 'Purchase',
        partnerId: _selectedVendor!.id,
        partner: _selectedVendor,
        projectId: _selectedProject?.id,
        project: _selectedProject,
        orderDate: _orderDate,
        status: _status,
        lines: _orderLines.map((line) => OrderLineModel(
          id: line.id,
          productId: line.product!.id,
          product: line.product,
          quantity: line.quantity,
          unit: line.unit,
          unitPrice: line.unitPrice,
          taxPercent: line.taxPercent,
          amount: line.amount,
        )).toList(),
        untaxedAmount: _untaxedAmount,
        totalAmount: _totalAmount,
        relatedInvoices: widget.order?.relatedInvoices ?? [],
      );

      final result = widget.order == null
          ? await _orderService.createOrder(orderData)
          : await _orderService.updateOrder(widget.order!.id, orderData.toCreateJson());

      if (mounted) {
        if (result['success']) {
          AppToast.showSuccess(
            context,
            widget.order == null
                ? 'Purchase order created successfully'
                : 'Purchase order updated successfully',
          );
          Navigator.pop(context, true);
        } else {
          AppToast.showError(
            context,
            result['message'] ?? 'Failed to save order',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.showError(context, 'An error occurred: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _orderDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.theme['primaryColor'],
              onPrimary: Colors.white,
              onSurface: AppColors.theme['textColor'],
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() => _orderDate = pickedDate);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (AppColors.theme['primaryColor'] as Color)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.shopping_cart_outlined,
                    color: AppColors.theme['primaryColor'],
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.order == null ? 'New Purchase Order' : 'Edit Purchase Order',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.theme['textColor'],
                        ),
                      ),
                      if (widget.order != null)
                        Text(
                          widget.order!.code,
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.theme['secondaryColor'],
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Content
            Flexible(
              child: _isLoadingData
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Vendor, Project, Date, and Status Row
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: _buildSearchableDropdown<PartnerModel>(
                                    label: 'Vendor',
                                    value: _selectedVendor,
                                    items: _vendors,
                                    itemLabel: (vendor) => vendor.name,
                                    onChanged: (vendor) {
                                      setState(() => _selectedVendor = vendor);
                                    },
                                    icon: Icons.business_outlined,
                                    isRequired: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  flex: 2,
                                  child: _buildSearchableDropdown<ProjectModel>(
                                    label: 'Project',
                                    value: _selectedProject,
                                    items: _projects,
                                    itemLabel: (project) => project.name,
                                    onChanged: (project) {
                                      setState(() => _selectedProject = project);
                                    },
                                    icon: Icons.folder_outlined,
                                    isRequired: true,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Order Date',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.theme['textColor'],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: _selectDate,
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 14,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF8FAFC),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.grey.shade300),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.calendar_today_outlined,
                                                  color: AppColors.theme['primaryColor'],
                                                  size: 18,
                                                ),
                                                const SizedBox(width: 12),
                                                Text(
                                                  DateFormat('MMM dd, yyyy').format(_orderDate),
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: AppColors.theme['textColor'],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Status',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.theme['textColor'],
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      DropdownButtonFormField<String>(
                                        value: _status,
                                        decoration: InputDecoration(
                                          filled: true,
                                          fillColor: const Color(0xFFF8FAFC),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                            borderSide: BorderSide(color: Colors.grey.shade300),
                                          ),
                                          contentPadding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                            vertical: 14,
                                          ),
                                        ),
                                        items: ['Draft', 'Confirmed', 'Done', 'Cancelled']
                                            .map((status) => DropdownMenuItem(
                                                  value: status,
                                                  child: Text(status),
                                                ))
                                            .toList(),
                                        onChanged: (value) {
                                          if (value != null) {
                                            setState(() => _status = value);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // Order Lines Section
                            Row(
                              children: [
                                Text(
                                  'Order Lines',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.theme['textColor'],
                                  ),
                                ),
                                const Spacer(),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _addOrderLine,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            AppColors.theme['primaryColor'],
                                            (AppColors.theme['primaryColor'] as Color)
                                                .withValues(alpha: 0.85),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Row(
                                        children: [
                                          Icon(Icons.add, color: Colors.white, size: 18),
                                          SizedBox(width: 6),
                                          Text(
                                            'Add Product',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Order Lines Table
                            Container(
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Column(
                                children: [
                                  // Table Header
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: (AppColors.theme['primaryColor'] as Color)
                                          .withValues(alpha: 0.05),
                                      borderRadius: const BorderRadius.vertical(
                                        top: Radius.circular(12),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            'PRODUCT',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.theme['secondaryColor'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'QUANTITY',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.theme['secondaryColor'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'UNIT',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.theme['secondaryColor'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'UNIT PRICE',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.theme['secondaryColor'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            'TAX %',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.theme['secondaryColor'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'AMOUNT',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: AppColors.theme['secondaryColor'],
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 40),
                                      ],
                                    ),
                                  ),
                                  // Table Body
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _orderLines.length,
                                    itemBuilder: (context, index) {
                                      return _buildOrderLineRow(index);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Totals Section
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: (AppColors.theme['primaryColor'] as Color)
                                    .withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (AppColors.theme['primaryColor'] as Color)
                                      .withValues(alpha: 0.2),
                                ),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      const Spacer(),
                                      Text(
                                        'Untaxed Amount:',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.theme['textColor'],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          '\$${_untaxedAmount.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.theme['textColor'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Spacer(),
                                      Text(
                                        'Total Amount:',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.theme['primaryColor'],
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      SizedBox(
                                        width: 150,
                                        child: Text(
                                          '\$${_totalAmount.toStringAsFixed(2)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.theme['primaryColor'],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(
                        color: AppColors.theme['secondaryColor'],
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.theme['textColor'],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CustomButton(
                    title: widget.order == null ? 'Create Purchase Order' : 'Save Changes',
                    onTap: _save,
                    isLoading: _isLoading,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderLineRow(int index) {
    final line = _orderLines[index];

    // Ensure unique products based on ID
    final uniqueProducts = <String, ProductModel>{};
    for (var product in _products) {
      uniqueProducts[product.id] = product;
    }
    final uniqueProductsList = uniqueProducts.values.toList();

    // Find matching product in unique list
    ProductModel? matchedProduct;
    if (line.product != null) {
      matchedProduct = uniqueProductsList.firstWhere(
        (p) => p.id == line.product!.id,
        orElse: () => line.product!,
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Dropdown
          Expanded(
            flex: 3,
            child: DropdownButtonFormField<ProductModel>(
              value: matchedProduct,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              isExpanded: true,
              hint: const Text('Select product', style: TextStyle(fontSize: 13)),
              items: uniqueProductsList
                  .map((product) => DropdownMenuItem(
                        value: product,
                        child: Text(
                          product.name,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ))
                  .toList(),
              onChanged: (product) {
                if (product != null) {
                  _updateOrderLine(
                    index,
                    line.copyWith(
                      product: product,
                      unit: product.unit,
                      taxPercent: product.saleTax,
                    ),
                  );
                }
              },
            ),
          ),
          const SizedBox(width: 12),

          // Quantity
          Expanded(
            child: TextFormField(
              initialValue: line.quantity > 0 ? line.quantity.toString() : '',
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
              ),
              style: const TextStyle(fontSize: 13),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (value) {
                final qty = int.tryParse(value) ?? 0;
                _updateOrderLine(index, line.copyWith(quantity: qty));
              },
            ),
          ),
          const SizedBox(width: 12),

          // Unit (Read-only)
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                line.unit.isEmpty ? '-' : line.unit,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.theme['secondaryColor'],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Unit Price
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: line.unitPrice > 0 ? line.unitPrice.toStringAsFixed(2) : '',
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                isDense: true,
                prefixText: '\$ ',
              ),
              style: const TextStyle(fontSize: 13),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
              ],
              onChanged: (value) {
                final price = double.tryParse(value) ?? 0.0;
                _updateOrderLine(index, line.copyWith(unitPrice: price));
              },
            ),
          ),
          const SizedBox(width: 12),

          // Tax %
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                line.taxPercent > 0 ? '${line.taxPercent.toStringAsFixed(0)}%' : '-',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.theme['secondaryColor'],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Amount (Calculated)
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: (AppColors.theme['primaryColor'] as Color)
                    .withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (AppColors.theme['primaryColor'] as Color)
                      .withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                '\$${line.totalAmount.toStringAsFixed(2)}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.theme['primaryColor'],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Delete Button
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => _removeOrderLine(index),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  size: 18,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchableDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required void Function(T?) onChanged,
    required IconData icon,
    bool isRequired = false,
  }) {
    // Ensure unique items based on their ID (for models with id property)
    final uniqueItems = <String, T>{};
    for (var item in items) {
      String itemId;
      if (item is PartnerModel) {
        itemId = item.id;
      } else if (item is ProjectModel) {
        itemId = item.id;
      } else if (item is ProductModel) {
        itemId = item.id;
      } else {
        itemId = item.hashCode.toString();
      }
      uniqueItems[itemId] = item;
    }
    final uniqueItemsList = uniqueItems.values.toList();

    // Find the matching value in the unique items list
    T? matchedValue;
    if (value != null) {
      String valueId;
      if (value is PartnerModel) {
        valueId = value.id;
      } else if (value is ProjectModel) {
        valueId = value.id;
      } else if (value is ProductModel) {
        valueId = value.id;
      } else {
        valueId = value.hashCode.toString();
      }

      matchedValue = uniqueItemsList.firstWhere(
        (item) {
          String itemId;
          if (item is PartnerModel) {
            itemId = item.id;
          } else if (item is ProjectModel) {
            itemId = item.id;
          } else if (item is ProductModel) {
            itemId = item.id;
          } else {
            itemId = item.hashCode.toString();
          }
          return itemId == valueId;
        },
        orElse: () => value,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.theme['textColor'],
              ),
            ),
            if (isRequired)
              Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade600,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => _showSearchableDialog<T>(
              context: context,
              title: 'Select $label',
              items: uniqueItemsList,
              itemLabel: itemLabel,
              selectedValue: matchedValue,
              onSelected: onChanged,
              icon: icon,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.theme['primaryColor'], size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      matchedValue != null ? itemLabel(matchedValue) : 'Select $label',
                      style: TextStyle(
                        fontSize: 14,
                        color: matchedValue != null
                            ? AppColors.theme['textColor']
                            : AppColors.theme['secondaryColor'],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: AppColors.theme['secondaryColor'],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showSearchableDialog<T>({
    required BuildContext context,
    required String title,
    required List<T> items,
    required String Function(T) itemLabel,
    required T? selectedValue,
    required void Function(T?) onSelected,
    required IconData icon,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return _SearchableDropdownDialog<T>(
          title: title,
          items: items,
          itemLabel: itemLabel,
          selectedValue: selectedValue,
          onSelected: (value) {
            onSelected(value);
            Navigator.pop(dialogContext);
          },
          icon: icon,
        );
      },
    );
  }
}

// Helper class for managing order lines in the UI
class OrderLineItem {
  final String? id;
  final ProductModel? product;
  final String? productId;
  final int quantity;
  final String unit;
  final double unitPrice;
  final double taxPercent;

  OrderLineItem({
    this.id,
    this.product,
    this.productId,
    this.quantity = 0,
    this.unit = '',
    this.unitPrice = 0.0,
    this.taxPercent = 0.0,
  });

  double get amount => quantity * unitPrice;
  double get taxAmount => amount * (taxPercent / 100);
  double get totalAmount => amount + taxAmount;

  OrderLineItem copyWith({
    String? id,
    ProductModel? product,
    String? productId,
    int? quantity,
    String? unit,
    double? unitPrice,
    double? taxPercent,
  }) {
    return OrderLineItem(
      id: id ?? this.id,
      product: product ?? this.product,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      unitPrice: unitPrice ?? this.unitPrice,
      taxPercent: taxPercent ?? this.taxPercent,
    );
  }
}

// Searchable dropdown dialog widget
class _SearchableDropdownDialog<T> extends StatefulWidget {
  final String title;
  final List<T> items;
  final String Function(T) itemLabel;
  final T? selectedValue;
  final void Function(T) onSelected;
  final IconData icon;

  const _SearchableDropdownDialog({
    required this.title,
    required this.items,
    required this.itemLabel,
    required this.selectedValue,
    required this.onSelected,
    required this.icon,
  });

  @override
  State<_SearchableDropdownDialog<T>> createState() =>
      _SearchableDropdownDialogState<T>();
}

class _SearchableDropdownDialogState<T>
    extends State<_SearchableDropdownDialog<T>> {
  late List<T> _filteredItems;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
    _searchController.addListener(_filterItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterItems() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items.where((item) {
          return widget.itemLabel(item).toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: 450,
        constraints: const BoxConstraints(maxHeight: 600),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: (AppColors.theme['primaryColor'] as Color)
                        .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    widget.icon,
                    color: AppColors.theme['primaryColor'],
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['textColor'],
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Field
            TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: const Color(0xFFF8FAFC),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: AppColors.theme['primaryColor'],
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Items List
            Flexible(
              child: _filteredItems.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: AppColors.theme['secondaryColor'],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No items found',
                              style: TextStyle(
                                fontSize: 16,
                                color: AppColors.theme['secondaryColor'],
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = _filteredItems[index];
                        final isSelected = widget.selectedValue != null &&
                            _getItemId(item) == _getItemId(widget.selectedValue as T);

                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => widget.onSelected(item),
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? (AppColors.theme['primaryColor'] as Color)
                                        .withValues(alpha: 0.1)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.theme['primaryColor']
                                      : Colors.grey.shade200,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.itemLabel(item),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: isSelected
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? AppColors.theme['primaryColor']
                                            : AppColors.theme['textColor'],
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.theme['primaryColor'],
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _getItemId(T item) {
    if (item is PartnerModel) return item.id;
    if (item is ProjectModel) return item.id;
    if (item is ProductModel) return item.id;
    return item.hashCode.toString();
  }
}
