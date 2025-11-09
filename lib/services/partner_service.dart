import 'dart:convert';
import 'package:frontend/models/partner_model.dart';
import 'package:frontend/services/api_service.dart';

class PartnerService {
  // Create a new partner
  Future<Map<String, dynamic>> createPartner(PartnerModel partner) async {
    try {
      print('📤 Creating partner: ${partner.name}');
      final response = await ApiService.post(
        '/api/partner',
        partner.toCreateJson(),
        needsAuth: true,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('✅ Partner created successfully');
        return {
          'success': true,
          'data': PartnerModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to create partner',
        };
      }
    } catch (e) {
      print('❌ Error creating partner: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Get all partners
  Future<Map<String, dynamic>> getAllPartners() async {
    try {
      print('📤 Fetching all partners');
      final response = await ApiService.get('/api/partner', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<PartnerModel> partners = [];
        if (data['data'] != null) {
          partners = (data['data'] as List)
              .map((partner) => PartnerModel.fromJson(partner))
              .toList();
        }

        print('✅ Retrieved ${partners.length} partners');
        return {
          'success': true,
          'data': partners,
          'count': data['count'] ?? partners.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch partners',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching partners: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // Get partners by type (Customer or Vendor)
  Future<Map<String, dynamic>> getPartnersByType(String type) async {
    try {
      print('📤 Fetching partners of type: $type');
      final response = await ApiService.get('/api/partner?type=$type', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<PartnerModel> partners = [];
        if (data['data'] != null) {
          partners = (data['data'] as List)
              .map((partner) => PartnerModel.fromJson(partner))
              .toList();
        }

        print('✅ Retrieved ${partners.length} $type partners');
        return {
          'success': true,
          'data': partners,
          'count': data['count'] ?? partners.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to fetch partners',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error fetching partners by type: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }

  // Get a single partner by ID
  Future<Map<String, dynamic>> getPartnerById(String partnerId) async {
    try {
      print('📤 Fetching partner with ID: $partnerId');
      final response = await ApiService.get('/api/partner/$partnerId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Partner retrieved successfully');
        return {
          'success': true,
          'data': PartnerModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to fetch partner',
        };
      }
    } catch (e) {
      print('❌ Error fetching partner: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Update a partner
  Future<Map<String, dynamic>> updatePartner(
      String partnerId, Map<String, dynamic> updates) async {
    try {
      print('📤 Updating partner with ID: $partnerId');
      final response = await ApiService.put(
        '/api/partner/$partnerId',
        updates,
        needsAuth: true,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Partner updated successfully');
        return {
          'success': true,
          'data': PartnerModel.fromJson(data['data']),
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to update partner',
        };
      }
    } catch (e) {
      print('❌ Error updating partner: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Delete a partner
  Future<Map<String, dynamic>> deletePartner(String partnerId) async {
    try {
      print('📤 Deleting partner with ID: $partnerId');
      final response = await ApiService.delete('/api/partner/$partnerId', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('✅ Partner deleted successfully');
        return {
          'success': true,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        final data = jsonDecode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to delete partner',
        };
      }
    } catch (e) {
      print('❌ Error deleting partner: $e');
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Search partners by name
  Future<Map<String, dynamic>> searchPartners(String query) async {
    try {
      print('📤 Searching partners with query: $query');
      final response = await ApiService.get('/api/partner?search=$query', needsAuth: true);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<PartnerModel> partners = [];
        if (data['data'] != null) {
          partners = (data['data'] as List)
              .map((partner) => PartnerModel.fromJson(partner))
              .toList();
        }

        print('✅ Found ${partners.length} partners matching "$query"');
        return {
          'success': true,
          'data': partners,
          'count': data['count'] ?? partners.length,
          'message': data['message'],
        };
      } else {
        return {
          'success': false,
          'message': 'Failed to search partners',
          'data': [],
        };
      }
    } catch (e) {
      print('❌ Error searching partners: $e');
      return {
        'success': false,
        'message': e.toString(),
        'data': [],
      };
    }
  }
}
