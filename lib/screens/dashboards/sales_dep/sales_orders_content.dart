import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/services/order_service.dart';
import 'package:frontend/services/toast_service.dart';
import 'package:intl/intl.dart';
import 'add_edit_order_dialog.dart';

class SalesOrdersContent extends StatefulWidget {
  const SalesOrdersContent({super.key});

  @override
  State<SalesOrdersContent> createState() => _SalesOrdersContentState();
}

class _SalesOrdersContentState extends State<SalesOrdersContent> {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _filterStatus = 'All';
  String _sortBy = 'Date (Newest)';
  int _currentPage = 1;
  final int _itemsPerPage = 10;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final result = await _orderService.getOrdersByType('Sales');
    if (result['success']) {
      setState(() {
        _orders = result['data'];
      });
    } else {
      if (mounted) {
        AppToast.showError(context, result['message'] ?? 'Failed to load orders');
      }
    }
    setState(() => _isLoading = false);
  }

  List<OrderModel> get _filteredOrders {
    var filtered = _orders.where((order) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          order.code.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.partnerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.projectName.toLowerCase().contains(_searchQuery.toLowerCase());

      // Status filter
      final matchesStatus = _filterStatus == 'All' ||
          order.status.toLowerCase() == _filterStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    // Sort
    switch (_sortBy) {
      case 'Date (Newest)':
        filtered.sort((a, b) => b.orderDate.compareTo(a.orderDate));
        break;
      case 'Date (Oldest)':
        filtered.sort((a, b) => a.orderDate.compareTo(b.orderDate));
        break;
      case 'Amount (High to Low)':
        filtered.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        break;
      case 'Amount (Low to High)':
        filtered.sort((a, b) => a.totalAmount.compareTo(b.totalAmount));
        break;
      case 'Customer (A-Z)':
        filtered.sort((a, b) => a.partnerName.compareTo(b.partnerName));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredOrders = _filteredOrders;

    // Pagination
    final totalPages = (filteredOrders.length / _itemsPerPage).ceil();
    if (totalPages > 0 && _currentPage > totalPages) {
      _currentPage = totalPages;
    }
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = (startIndex + _itemsPerPage).clamp(0, filteredOrders.length);
    final paginatedOrders = filteredOrders.sublist(
      startIndex.clamp(0, filteredOrders.length),
      endIndex,
    );

    return Container(
      color: AppColors.theme['backgroundColor'],
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Section
          _buildHeader(),
          const SizedBox(height: 32),

          // Orders Table
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildOrdersTable(paginatedOrders),
          ),

          // Pagination
          if (totalPages > 1) ...[
            const SizedBox(height: 24),
            _buildPagination(totalPages),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.theme['primaryColor'],
                      (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sales Orders',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['textColor'],
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your sales orders and track order status',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.theme['secondaryColor'],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Icon(Icons.shopping_cart_rounded, color: AppColors.theme['primaryColor'], size: 24),
                    const SizedBox(height: 4),
                    Text(
                      '${_orders.length}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.theme['primaryColor'],
                      ),
                    ),
                    Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.theme['secondaryColor'],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          const Divider(height: 1),
          const SizedBox(height: 20),
          Row(
            children: [
              // Search Bar
              Expanded(
                flex: 3,
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    onChanged: (value) => setState(() {
                      _searchQuery = value;
                      _currentPage = 1;
                    }),
                    decoration: InputDecoration(
                      hintText: 'Search by order code, customer, or project...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: AppColors.theme['primaryColor'],
                        size: 22,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  _searchQuery = '';
                                  _currentPage = 1;
                                }),
                                child: const Icon(
                                  Icons.clear_rounded,
                                  color: Color(0xFF94A3B8),
                                  size: 20,
                                ),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Sort Dropdown
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: Icon(Icons.sort_rounded, color: AppColors.theme['primaryColor']),
                  items: [
                    'Date (Newest)',
                    'Date (Oldest)',
                    'Amount (High to Low)',
                    'Amount (Low to High)',
                    'Customer (A-Z)',
                  ]
                      .map((sort) => DropdownMenuItem(
                            value: sort,
                            child: Text(
                              sort,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _sortBy = value);
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Filter Dropdown
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButton<String>(
                  value: _filterStatus,
                  underline: const SizedBox(),
                  icon: Icon(Icons.filter_list_rounded, color: AppColors.theme['primaryColor']),
                  items: ['All', 'Draft', 'Confirmed', 'Done', 'Cancelled']
                      .map((status) => DropdownMenuItem(
                            value: status,
                            child: Text(
                              status,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _filterStatus = value;
                        _currentPage = 1;
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 16),

              // Refresh Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: _loadOrders,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.refresh_rounded, color: Colors.white, size: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Add Order Button
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => _showAddOrderDialog(),
                  child: Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.theme['primaryColor'],
                          (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.85),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.4),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.add_rounded, color: Colors.white, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Add Order',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTable(List<OrderModel> orders) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: (AppColors.theme['secondaryColor'] as Color).withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No sales orders found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.theme['secondaryColor'],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _filterStatus != 'All'
                  ? 'Try adjusting your search or filters'
                  : 'Create your first sales order',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.theme['secondaryColor'],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    'ORDER CODE',
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
                    'CUSTOMER',
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
                    'PROJECT',
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
                    'ORDER DATE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['secondaryColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Text(
                    'STATUS',
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
                    'TOTAL AMOUNT',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.theme['secondaryColor'],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(
                  width: 100,
                  child: Text(
                    'ACTIONS',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Table Body
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderRow(order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderRow(OrderModel order) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => _showEditOrderDialog(order),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade100),
            ),
          ),
          child: Row(
            children: [
              // Order Code
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.theme['primaryColor'],
                            (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.7),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.receipt_long,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        order.code,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.theme['textColor'],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              // Customer
              Expanded(
                flex: 2,
                child: Text(
                  order.partnerName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme['textColor'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Project
              Expanded(
                flex: 2,
                child: Text(
                  order.projectName,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme['secondaryColor'],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              // Order Date
              Expanded(
                flex: 2,
                child: Text(
                  DateFormat('MMM dd, yyyy').format(order.orderDate),
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.theme['secondaryColor'],
                  ),
                ),
              ),

              // Status
              Expanded(
                flex: 1,
                child: _buildStatusBadge(order.status),
              ),

              // Total Amount
              Expanded(
                flex: 2,
                child: Text(
                  '\$${order.totalAmount.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppColors.theme['primaryColor'],
                  ),
                ),
              ),

              // Actions
              SizedBox(
                width: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _showEditOrderDialog(order),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => _deleteOrder(order),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.delete_rounded,
                            size: 16,
                            color: Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;

    switch (status.toLowerCase()) {
      case 'draft':
        bgColor = const Color(0xFF94A3B8).withValues(alpha: 0.1);
        textColor = const Color(0xFF64748B);
        break;
      case 'confirmed':
        bgColor = const Color(0xFF3B82F6).withValues(alpha: 0.1);
        textColor = const Color(0xFF3B82F6);
        break;
      case 'done':
        bgColor = const Color(0xFF10B981).withValues(alpha: 0.1);
        textColor = const Color(0xFF10B981);
        break;
      case 'cancelled':
        bgColor = const Color(0xFFEF4444).withValues(alpha: 0.1);
        textColor = const Color(0xFFEF4444);
        break;
      default:
        bgColor = Colors.grey.withValues(alpha: 0.1);
        textColor = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildPagination(int totalPages) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        MouseRegion(
          cursor: _currentPage > 1 ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _currentPage > 1 ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Previous',
                style: TextStyle(
                  color: _currentPage > 1 ? AppColors.theme['textColor'] : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ...List.generate(totalPages > 5 ? 5 : totalPages, (index) {
          final pageNum = index + 1;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _currentPage = pageNum),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: _currentPage == pageNum
                        ? LinearGradient(
                            colors: [
                              AppColors.theme['primaryColor'],
                              (AppColors.theme['primaryColor'] as Color).withValues(alpha: 0.8),
                            ],
                          )
                        : null,
                    color: _currentPage == pageNum ? null : Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _currentPage == pageNum
                          ? AppColors.theme['primaryColor']
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$pageNum',
                      style: TextStyle(
                        color: _currentPage == pageNum ? Colors.white : AppColors.theme['textColor'],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 16),
        MouseRegion(
          cursor: _currentPage < totalPages ? SystemMouseCursors.click : SystemMouseCursors.basic,
          child: GestureDetector(
            onTap: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _currentPage < totalPages ? Colors.white : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Text(
                'Next',
                style: TextStyle(
                  color: _currentPage < totalPages ? AppColors.theme['textColor'] : Colors.grey.shade400,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showAddOrderDialog() async {
    final result = await showDialog(
      context: context,
      builder: (context) => const AddEditOrderDialog(),
    );
    if (result == true) {
      _loadOrders();
    }
  }

  Future<void> _showEditOrderDialog(OrderModel order) async {
    final result = await showDialog(
      context: context,
      builder: (context) => AddEditOrderDialog(order: order),
    );
    if (result == true) {
      _loadOrders();
    }
  }

  Future<void> _deleteOrder(OrderModel order) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Sales Order'),
        content: Text('Are you sure you want to delete ${order.code}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final result = await _orderService.deleteOrder(order.id);
      if (mounted) {
        if (result['success']) {
          AppToast.showSuccess(context, 'Sales order deleted successfully');
          _loadOrders();
        } else {
          AppToast.showError(context, result['message'] ?? 'Failed to delete order');
        }
      }
    }
  }
}
