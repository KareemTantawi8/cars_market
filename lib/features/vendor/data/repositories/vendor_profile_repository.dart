import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/vendor_profile_model.dart';

/// Vendor Profile Repository - Handles vendor profile API calls
class VendorProfileRepository {
  final ApiClient _apiClient;

  VendorProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    if (kDebugMode) {
      debugPrint('👤 VendorProfileRepository: $message');
    }
  }

  /// Get vendor profile by vendor ID
  /// GET /api/v1/vendors/:id
  Future<VendorProfileModel> getVendorProfile(int vendorId) async {
    _log('📋 Fetching vendor profile for vendor ID: $vendorId');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vendorById(vendorId),
      );

      _log('✅ Vendor profile response status: ${response.statusCode}');
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final payload = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
          final result = VendorProfileModel.fromJson(payload);
          _log('✅ Parsed vendor profile: ${result.name}');
          return result;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to fetch vendor profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException fetching vendor profile: ${e.message}');
      if (e.response != null) {
        if (e.response!.statusCode == 404) throw Exception('التاجر غير موجود');
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'فشل في جلب بيانات التاجر'
            : 'فشل في جلب بيانات التاجر';
        throw Exception(errorMessage);
      }
      throw Exception('خطأ في الشبكة: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error fetching vendor profile: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }

  /// Get vendor profile from /profile endpoint (governorate, categories, user details)
  /// GET /api/v1/vendors/:id/profile. 200/404.
  Future<VendorProfileModel> getVendorProfilePage(int vendorId) async {
    _log('📋 Fetching vendor profile page for vendor ID: $vendorId');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vendorProfileById(vendorId),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch vendor profile: ${response.statusCode}');
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('Invalid response format');
      final payload = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
      final result = VendorProfileModel.fromJson(payload);
      _log('✅ Parsed vendor profile page: ${result.name}');
      return result;
    } on DioException catch (e) {
      _log('❌ getVendorProfilePage: ${e.message}');
      if (e.response?.statusCode == 404) throw Exception('التاجر غير موجود');
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'فشل في جلب بيانات التاجر'
          : 'فشل في جلب بيانات التاجر';
      throw Exception(msg);
    }
  }

  /// Get vendor performance report (human-readable time fields etc.)
  /// GET /api/v1/vendors/:id/reports. 200/404.
  Future<Map<String, dynamic>> getVendorPerformanceReport(int vendorId) async {
    _log('📊 Fetching vendor performance report for vendor ID: $vendorId');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.vendorReportsById(vendorId),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch report: ${response.statusCode}');
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) return <String, dynamic>{};
      final inner = data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
      _log('✅ Vendor report loaded');
      return inner;
    } on DioException catch (e) {
      _log('❌ getVendorPerformanceReport: ${e.message}');
      if (e.response?.statusCode == 404) throw Exception('التقرير غير متوفر');
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'فشل في جلب التقرير'
          : 'فشل في جلب التقرير';
      throw Exception(msg);
    }
  }
}

