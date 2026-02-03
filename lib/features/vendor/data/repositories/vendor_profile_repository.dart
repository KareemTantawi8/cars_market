import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/vendor_profile_model.dart';

/// Vendor Profile Repository - Handles vendor profile API calls
class VendorProfileRepository {
  final ApiClient _apiClient;

  VendorProfileRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  void _log(String message) {
    // ignore: avoid_print
    print('👤 VendorProfileRepository: $message');
  }

  /// Get vendor profile by user ID
  /// GET /api/v1/users/:id
  Future<VendorProfileModel> getVendorProfile(int userId) async {
    _log('📋 Fetching vendor profile for user ID: $userId');
    try {
      final response = await _apiClient.get(
        ApiEndpoints.userProfileById(userId),
      );

      _log('✅ Vendor profile response status: ${response.statusCode}');
      _log('📄 Vendor profile response data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data is Map<String, dynamic>) {
          final result = VendorProfileModel.fromJson(data);
          _log('✅ Parsed vendor profile: ${result.name}');
          return result;
        }
        throw Exception('Invalid response format');
      } else {
        throw Exception('Failed to fetch vendor profile: ${response.statusCode}');
      }
    } on DioException catch (e) {
      _log('❌ DioException fetching vendor profile: ${e.message}');
      _log('❌ Response: ${e.response?.data}');
      // Handle API errors
      if (e.response != null) {
        final errorData = e.response!.data;
        final errorMessage = errorData is Map<String, dynamic>
            ? errorData['message'] ?? errorData['error'] ?? 'فشل في جلب بيانات التاجر'
            : 'فشل في جلب بيانات التاجر';
        throw Exception(errorMessage);
      } else {
        throw Exception('خطأ في الشبكة: ${e.message}');
      }
    } catch (e) {
      _log('❌ Unexpected error fetching vendor profile: $e');
      throw Exception('حدث خطأ غير متوقع: $e');
    }
  }
}

