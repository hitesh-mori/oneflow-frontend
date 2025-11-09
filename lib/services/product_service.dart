import 'dart:convert';
import 'package:frontend/models/product_model.dart';
import 'package:frontend/services/api_service.dart';

class ProductService {
  // Create a new product
  Future<Map<String, dynamic>> createProduct(ProductModel product) async {
    try {
      print('📤 Creating product: ${product.name}');
      final response = await ApiService.post(
        '/api/product',
        product.toCreateJson(),
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Product created successfully');
        return {
          'success': true,
          'data': ProductModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create product',
        };
      }
    } catch (e) {
      print('❌ Error creating product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get all products
  Future<Map<String, dynamic>> getAllProducts() async {
    try {
      print('📤 Fetching all products');
      final response = await ApiService.get('/api/product', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<ProductModel> products = [];
        if (data['data'] != null) {
          products = (data['data'] as List)
              .map((product) => ProductModel.fromJson(product))
              .toList();
        }

        print('✅ Retrieved ${products.length} products');
        return {
          'success': true,
          'data': products,
          'count': data['count'] ?? products.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch products',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching products: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // Get products by type (sale or purchase)
  Future<Map<String, dynamic>> getProductsByType(String type) async {
    try {
      print('📤 Fetching products of type: $type');
      final response = await ApiService.get('/api/product?type=$type', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<ProductModel> products = [];
        if (data['data'] != null) {
          products = (data['data'] as List)
              .map((product) => ProductModel.fromJson(product))
              .toList();
        }

        print('✅ Retrieved ${products.length} $type products');
        return {
          'success': true,
          'data': products,
          'count': data['count'] ?? products.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch products',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching products by type: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // Get a single product by ID
  Future<Map<String, dynamic>> getProductById(String productId) async {
    try {
      print('📤 Fetching product with ID: $productId');
      final response = await ApiService.get('/api/product/$productId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Product retrieved successfully');
        return {
          'success': true,
          'data': ProductModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch product',
        };
      }
    } catch (e) {
      print('❌ Error fetching product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Update a product
  Future<Map<String, dynamic>> updateProduct(
      String productId, Map<String, dynamic> updates) async {
    try {
      print('📤 Updating product with ID: $productId');
      final response = await ApiService.put(
        '/api/product/$productId',
        updates,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Product updated successfully');
        return {
          'success': true,
          'data': ProductModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update product',
        };
      }
    } catch (e) {
      print('❌ Error updating product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete a product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      print('📤 Deleting product with ID: $productId');
      final response = await ApiService.delete('/api/product/$productId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Product deleted successfully');
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete product',
        };
      }
    } catch (e) {
      print('❌ Error deleting product: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Search products by name
  Future<Map<String, dynamic>> searchProducts(String query) async {
    try {
      print('📤 Searching products with query: $query');
      final response = await ApiService.get('/api/product?search=$query', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<ProductModel> products = [];
        if (data['data'] != null) {
          products = (data['data'] as List)
              .map((product) => ProductModel.fromJson(product))
              .toList();
        }

        print('✅ Found ${products.length} products matching "$query"');
        return {
          'success': true,
          'data': products,
          'count': data['count'] ?? products.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to search products',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error searching products: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }
}
