import 'dart:convert';
import 'package:frontend/models/order_model.dart';
import 'package:frontend/services/api_service.dart';

class OrderService {
  // Create a new order
  Future<Map<String, dynamic>> createOrder(OrderModel order) async {
    try {
      print('📤 Creating ${order.type} order');
      final response = await ApiService.post(
        '/api/order',
        order.toCreateJson(),
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Order created successfully: ${data['data']['code']}');
        return {
          'success': true,
          'data': OrderModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create order',
        };
      }
    } catch (e) {
      print('❌ Error creating order: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get all orders
  Future<Map<String, dynamic>> getAllOrders() async {
    try {
      print('📤 Fetching all orders');
      final response = await ApiService.get('/api/order', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<OrderModel> orders = [];
        if (data['data'] != null) {
          orders = (data['data'] as List)
              .map((order) => OrderModel.fromJson(order))
              .toList();
        }

        print('✅ Retrieved ${orders.length} orders');
        return {
          'success': true,
          'data': orders,
          'count': data['count'] ?? orders.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching orders: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // Get orders by type (Sales or Purchase)
  Future<Map<String, dynamic>> getOrdersByType(String type) async {
    try {
      print('📤 Fetching $type orders');
      final response = await ApiService.get('/api/order?type=$type', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<OrderModel> orders = [];
        if (data['data'] != null) {
          orders = (data['data'] as List)
              .map((order) => OrderModel.fromJson(order))
              .toList();
        }

        print('✅ Retrieved ${orders.length} $type orders');
        return {
          'success': true,
          'data': orders,
          'count': data['count'] ?? orders.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch orders',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching orders by type: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // Get a single order by ID
  Future<Map<String, dynamic>> getOrderById(String orderId) async {
    try {
      print('📤 Fetching order with ID: $orderId');
      final response = await ApiService.get('/api/order/$orderId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order retrieved successfully');
        return {
          'success': true,
          'data': OrderModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch order',
        };
      }
    } catch (e) {
      print('❌ Error fetching order: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Update an order
  Future<Map<String, dynamic>> updateOrder(
      String orderId, Map<String, dynamic> updates) async {
    try {
      print('📤 Updating order with ID: $orderId');
      final response = await ApiService.put(
        '/api/order/$orderId',
        updates,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order updated successfully');
        return {
          'success': true,
          'data': OrderModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update order',
        };
      }
    } catch (e) {
      print('❌ Error updating order: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete an order
  Future<Map<String, dynamic>> deleteOrder(String orderId) async {
    try {
      print('📤 Deleting order with ID: $orderId');
      final response = await ApiService.delete('/api/order/$orderId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Order deleted successfully');
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete order',
        };
      }
    } catch (e) {
      print('❌ Error deleting order: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Confirm an order (change status to Confirmed)
  Future<Map<String, dynamic>> confirmOrder(String orderId) async {
    return updateOrder(orderId, {'status': 'Confirmed'});
  }

  // Mark order as done
  Future<Map<String, dynamic>> markOrderDone(String orderId) async {
    return updateOrder(orderId, {'status': 'Done'});
  }

  // Cancel an order
  Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    return updateOrder(orderId, {'status': 'Cancelled'});
  }
}
