import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/vendor_profile_model.dart';

/// Response model for location update
class LocationUpdateResponse {
  final double latitude;
  final double longitude;
  final String? googleMapsUrl;

  const LocationUpdateResponse({
    required this.latitude,
    required this.longitude,
    this.googleMapsUrl,
  });

  factory LocationUpdateResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return LocationUpdateResponse(
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      googleMapsUrl: data['google_maps_url'] as String?,
    );
  }
}

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

  static int? _vendorRecordIdFromUserPayload(Map<String, dynamic> map) {
    final v = map['vendor'];
    if (v is Map<String, dynamic>) {
      final raw = v['id'];
      if (raw is int && raw > 0) return raw;
      final p = int.tryParse(raw?.toString() ?? '');
      if (p != null && p > 0) return p;
    }
    final rawId = map['vendor_id'];
    if (rawId is int && rawId > 0) return rawId;
    final p2 = int.tryParse(rawId?.toString() ?? '');
    if (p2 != null && p2 > 0) return p2;
    return null;
  }

  /// Resolves [userId] (ad owner / account user id) to vendor profile via
  /// GET /api/v1/users/:id then GET /api/v1/vendors/:vendorId/profile.
  Future<VendorProfileModel> getVendorProfilePageForAdOwnerUser(int userId) async {
    _log('📋 Resolving vendor profile from ad owner user ID: $userId');
    try {
      final response = await _apiClient.get(ApiEndpoints.userProfileById(userId));
      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to fetch user: ${response.statusCode}');
      }
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('Invalid response format');

      final payload = data['data'] is Map<String, dynamic>
          ? data['data'] as Map<String, dynamic>
          : data;

      Map<String, dynamic> userMap;
      final userRaw = payload['user'];
      if (userRaw is Map<String, dynamic>) {
        userMap = userRaw;
      } else {
        userMap = payload;
      }

      var vendorRecordId = _vendorRecordIdFromUserPayload(userMap);
      vendorRecordId ??= _vendorRecordIdFromUserPayload(payload);
      if (vendorRecordId != null) {
        return getVendorProfilePage(vendorRecordId);
      }

      try {
        return await getVendorProfilePage(userId);
      } on DioException catch (e) {
        if (e.response?.statusCode == 404) {
          throw Exception('التاجر غير موجود');
        }
        rethrow;
      }
    } on DioException catch (e) {
      _log('❌ getVendorProfilePageForAdOwnerUser: ${e.message}');
      if (e.response?.statusCode == 404) throw Exception('التاجر غير موجود');
      final msg = e.response?.data is Map<String, dynamic>
          ? (e.response!.data as Map<String, dynamic>)['message']?.toString() ?? 'فشل في جلب بيانات التاجر'
          : 'فشل في جلب بيانات التاجر';
      throw Exception(msg);
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

  /// Update vendor GPS location.
  /// PUT /api/v1/profile/location - Body: { latitude, longitude }. Vendors only.
  Future<LocationUpdateResponse> updateVendorLocation({
    required double latitude,
    required double longitude,
  }) async {
    _log('📍 Updating vendor location: $latitude, $longitude');
    try {
      final response = await _apiClient.put(
        ApiEndpoints.profileLocation,
        data: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = LocationUpdateResponse.fromJson(data);
          _log('✅ Location updated successfully');
          return result;
        }
        throw Exception('Invalid response format');
      }
      throw Exception('Failed to update location: ${response.statusCode}');
    } on DioException catch (e) {
      _log('❌ updateVendorLocation: ${e.message}');
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message']?.toString() ?? 'فشل في تحديث الموقع'
            : 'فشل في تحديث الموقع';
        throw Exception(errorMessage);
      }
      throw Exception('خطأ في الشبكة: ${e.message}');
    } catch (e) {
      _log('❌ Unexpected error updating location: $e');
      rethrow;
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

